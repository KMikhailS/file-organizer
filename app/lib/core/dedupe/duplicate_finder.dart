import 'package:file_organizer/core/dedupe/dedupe_event.dart';
import 'package:file_organizer/core/dedupe/keeper_selection.dart';
import 'package:file_organizer/core/model/duplicate_group.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:file_organizer/core/ports/cancel_token.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_index_repository.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/zones/zone_map.dart';

/// Finds groups of identical files in one source.
///
/// - Cascade: same size → same partial hash → same full hash. Files up to
///   [fullHashOnlyUpTo] bytes skip the partial hash: it would read the
///   whole file anyway.
/// - Hashes come from the index when present; computed ones are written
///   back, so unchanged files are not read again.
/// - Empty files and files in excluded zones take no part.
/// - A file that cannot be hashed (locked, gone, no access) is left out and
///   reported; the rest goes on.
/// - Up to [hashConcurrency] files are hashed at the same time (reading
///   them waits on storage, not on the CPU). Results are taken in file
///   order, so groups, skips and progress are the same as one at a time.
/// - A cancelled [CancelToken] stops the search inside the current file
///   (the adapter checks it between read blocks): the stream ends without
///   [DedupeCompleted]. Hashes computed so far stay in the index.
///
/// Reads files only; never changes them.
final class DuplicateFinder {
  DuplicateFinder({required this._index, this.hashConcurrency = 4}) {
    if (hashConcurrency < 1) {
      throw ArgumentError.value(
        hashConcurrency,
        'hashConcurrency',
        'must be positive',
      );
    }
  }

  /// Files up to this size are hashed in full right away.
  static const int fullHashOnlyUpTo = 2 * 64 * 1024;

  /// How many files are hashed at the same time at most.
  final int hashConcurrency;

  final FileIndexRepository _index;

  /// Emits [DedupeProgress] after each size bucket and ends with
  /// [DedupeCompleted]. Cancelling the subscription stops after the current
  /// bucket; cancelling [cancel] stops inside the current file and ends the
  /// stream without [DedupeCompleted]. Hashes computed so far stay in the
  /// index either way.
  ///
  /// Throws [ArgumentError] right away if [zones] belong to another source.
  Stream<DedupeEvent> find(
    FileSource source,
    ZoneMap zones, {
    CancelToken? cancel,
  }) {
    if (zones.sourceId != source.sourceId) {
      throw ArgumentError.value(zones, 'zones', 'belongs to another source');
    }
    return _find(source, zones, cancel);
  }

  Stream<DedupeEvent> _find(
    FileSource source,
    ZoneMap zones,
    CancelToken? cancel,
  ) async* {
    final sourceId = source.sourceId;
    final run = _Run(source, _index, cancel, hashConcurrency);
    final sizes = [
      for (final size in await _index.sizesWithMultipleFiles(sourceId))
        if (size > 0) size,
    ];
    final groups = <DuplicateGroup>[];

    for (var i = 0; i < sizes.length; i++) {
      final size = sizes[i];
      final candidates = [
        for (final entry in await _index.bySize(sourceId, size))
          if (zones.zoneOfFile(entry.path) != Zone.excluded) entry,
      ];
      var buckets = [candidates];
      if (size > fullHashOnlyUpTo) {
        buckets = [
          for (final bucket in buckets) ...await run.split(bucket, full: false),
        ];
      }
      if (run.cancelled) {
        return;
      }
      for (final bucket in buckets) {
        final split = await run.split(bucket, full: true);
        if (run.cancelled) {
          return;
        }
        for (final same in split) {
          final choice = chooseKeeper(same, (f) => zones.zoneOfFile(f.path));
          groups.add(
            DuplicateGroup(
              fullHash: same.first.fullHash!,
              files: same,
              keeper: choice.keeper,
              keeperReason: choice.reason,
            ),
          );
        }
      }
      yield DedupeProgress(
        sourceId,
        sizesDone: i + 1,
        sizesTotal: sizes.length,
        filesHashed: run.hashed,
      );
    }

    groups.sort((a, b) => a.keeper.path.compareTo(b.keeper.path));
    yield DedupeCompleted(
      sourceId,
      groups: groups,
      skipped: run.skipped,
      filesHashed: run.hashed,
    );
  }
}

/// State of one detection run.
final class _Run {
  _Run(this._source, this._index, this._cancel, this._concurrency);

  final FileSource _source;
  final FileIndexRepository _index;
  final CancelToken? _cancel;
  final int _concurrency;
  final List<DedupeSkip> skipped = [];
  int hashed = 0;

  /// Whether the token was cancelled; then [split] returns no buckets.
  bool get cancelled => _cancel?.isCancelled ?? false;

  /// Splits [files] by partial or full hash, computing missing hashes and
  /// caching them in the index. Returns only buckets of two or more files,
  /// in order of first appearance.
  Future<List<List<FileEntry>>> split(
    List<FileEntry> files, {
    required bool full,
  }) async {
    if (files.length < 2 || cancelled) {
      return const [];
    }
    String? cached(FileEntry entry) =>
        full ? entry.fullHash : entry.partialHash;

    // Missing hashes are requested in file order, at most [_concurrency]
    // at a time; each result is used in file order below.
    final requests = List<Future<FileResult<String>>?>.filled(
      files.length,
      null,
    );
    var next = 0;
    void requestNext() {
      // After a cancel nothing new is started.
      while (next < files.length && !cancelled) {
        final i = next++;
        final path = files[i].path;
        if (cached(files[i]) == null) {
          requests[i] = full
              ? _source.fullHash(path, cancel: _cancel)
              : _source.partialHash(path, cancel: _cancel);
          return;
        }
      }
    }

    for (var k = 0; k < _concurrency; k++) {
      requestNext();
    }

    final byHash = <String, List<FileEntry>>{};
    final computed = <FileEntry>[];
    files:
    for (final (i, file) in files.indexed) {
      var entry = file;
      var hash = cached(entry);
      if (hash == null) {
        final request = requests[i];
        if (request == null) {
          // Never requested: the search was cancelled before its turn.
          break files;
        }
        final result = await request;
        requestNext();
        switch (result) {
          case FileFailure(error: FileError(kind: FileErrorKind.cancelled)):
            // Not a problem of this file: the whole search stops.
            break files;
          case FileFailure(:final error):
            skipped.add(DedupeSkip(entry.path, error));
            continue;
          case FileSuccess(:final value):
            hash = value;
            hashed++;
            entry = full
                ? entry.withFullHash(value)
                : entry.withPartialHash(value);
            computed.add(entry);
        }
      }
      (byHash[hash] ??= []).add(entry);
    }
    // After a cancel, the requests still in flight end too (they see the
    // token): nothing reads on once the search has stopped.
    await Future.wait([...requests.nonNulls]);
    if (computed.isNotEmpty) {
      await _index.upsertAll(computed);
    }
    if (cancelled) {
      return const [];
    }
    return [
      for (final bucket in byHash.values)
        if (bucket.length > 1) bucket,
    ];
  }
}
