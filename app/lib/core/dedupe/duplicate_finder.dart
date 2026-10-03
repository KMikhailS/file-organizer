import 'package:file_organizer/core/dedupe/dedupe_event.dart';
import 'package:file_organizer/core/dedupe/keeper_selection.dart';
import 'package:file_organizer/core/model/duplicate_group.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/zone.dart';
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
///
/// Reads files only; never changes them.
final class DuplicateFinder {
  DuplicateFinder({required this._index});

  /// Files up to this size are hashed in full right away.
  static const int fullHashOnlyUpTo = 2 * 64 * 1024;

  final FileIndexRepository _index;

  /// Emits [DedupeProgress] after each size bucket and ends with
  /// [DedupeCompleted]. Cancelling the subscription stops after the current
  /// bucket; hashes computed so far stay in the index.
  ///
  /// Throws [ArgumentError] right away if [zones] belong to another source.
  Stream<DedupeEvent> find(FileSource source, ZoneMap zones) {
    if (zones.sourceId != source.sourceId) {
      throw ArgumentError.value(zones, 'zones', 'belongs to another source');
    }
    return _find(source, zones);
  }

  Stream<DedupeEvent> _find(FileSource source, ZoneMap zones) async* {
    final sourceId = source.sourceId;
    final run = _Run(source, _index);
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
      for (final bucket in buckets) {
        for (final same in await run.split(bucket, full: true)) {
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
  _Run(this._source, this._index);

  final FileSource _source;
  final FileIndexRepository _index;
  final List<DedupeSkip> skipped = [];
  int hashed = 0;

  /// Splits [files] by partial or full hash, computing missing hashes and
  /// caching them in the index. Returns only buckets of two or more files,
  /// in order of first appearance.
  Future<List<List<FileEntry>>> split(
    List<FileEntry> files, {
    required bool full,
  }) async {
    if (files.length < 2) {
      return const [];
    }
    final byHash = <String, List<FileEntry>>{};
    final computed = <FileEntry>[];
    for (final file in files) {
      var entry = file;
      var hash = full ? entry.fullHash : entry.partialHash;
      if (hash == null) {
        final result = full
            ? await _source.fullHash(entry.path)
            : await _source.partialHash(entry.path);
        switch (result) {
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
    if (computed.isNotEmpty) {
      await _index.upsertAll(computed);
    }
    return [
      for (final bucket in byHash.values)
        if (bucket.length > 1) bucket,
    ];
  }
}
