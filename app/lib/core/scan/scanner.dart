import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/scan_checkpoint.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:file_organizer/core/ports/file_index_repository.dart';
import 'package:file_organizer/core/ports/file_list_page.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/id_generator.dart';
import 'package:file_organizer/core/ports/scan_checkpoint_repository.dart';
import 'package:file_organizer/core/scan/scan_event.dart';
import 'package:file_organizer/core/scan/scan_summary.dart';

/// Keeps the file index in line with a source.
///
/// - A file with the same size and modification time as in the index keeps
///   its hashes; a changed file gets new metadata and loses its hashes.
/// - Files not seen in a completed scan are removed from the index.
/// - After every page the position is saved, so an interrupted scan (crash,
///   cancellation, listing failure) resumes where it stopped.
/// - Folders for which `skipFolder` returns `true` (excluded zones) are not
///   entered; their files leave the index.
///
/// Scanning only reads the source; it never changes files.
final class Scanner {
  Scanner({
    required this._index,
    required this._checkpoints,
    required this._ids,
  });

  final FileIndexRepository _index;
  final ScanCheckpointRepository _checkpoints;
  final IdGenerator _ids;

  /// Scans [source], resuming an unfinished scan of it if there is one.
  ///
  /// Emits [ScanProgress] after every indexed page and ends with
  /// [ScanCompleted] or [ScanFailed]. Cancelling the subscription stops the
  /// scan after the current page; the next call resumes it.
  Stream<ScanEvent> scan(
    FileSource source, {
    bool Function(LogicalPath folder)? skipFolder,
  }) async* {
    final sourceId = source.sourceId;
    final stored = await _checkpoints.bySource(sourceId);
    final checkpoint =
        stored ??
        ScanCheckpoint(
          sourceId: sourceId,
          scanId: ScanId(_ids.newId()),
          stage: ScanStage.listing,
        );
    if (stored == null) {
      await _checkpoints.save(checkpoint);
    }
    final scanId = checkpoint.scanId;

    var added = 0;
    var updated = 0;
    var unchanged = 0;
    final inaccessible = <LogicalPath>[];

    if (checkpoint.stage == ScanStage.listing) {
      ScanCursor? cursor = checkpoint.cursor;
      await for (final result in source.list(
        after: cursor,
        skipFolder: skipFolder,
      )) {
        final FileListPage page;
        switch (result) {
          case FileFailure(:final error):
            yield ScanFailed(
              sourceId,
              error: error,
              filesProcessed: added + updated + unchanged,
            );
            return;
          case FileSuccess(:final value):
            page = value;
        }

        final known = await _index.byPaths(
          sourceId,
          page.entries.map((e) => e.path),
        );
        final merged = <FileEntry>[];
        for (final listed in page.entries) {
          if (listed.sourceId != sourceId) {
            throw StateError(
              'Source $sourceId listed ${listed.path} of ${listed.sourceId}',
            );
          }
          final previous = known[listed.path];
          final same =
              previous != null &&
              previous.size == listed.size &&
              previous.modifiedAt == listed.modifiedAt;
          if (previous == null) {
            added++;
          } else if (same) {
            unchanged++;
          } else {
            updated++;
          }
          merged.add(
            FileEntry(
              sourceId: sourceId,
              path: listed.path,
              size: listed.size,
              modifiedAt: listed.modifiedAt,
              capturedAt: listed.capturedAt,
              mimeType: listed.mimeType,
              partialHash: same ? previous.partialHash : null,
              fullHash: same ? previous.fullHash : null,
              lastSeenScanId: scanId,
            ),
          );
        }

        await _index.upsertAll(merged);
        cursor = page.cursor;
        await _checkpoints.save(
          ScanCheckpoint(
            sourceId: sourceId,
            scanId: scanId,
            stage: ScanStage.listing,
            cursor: cursor,
          ),
        );
        inaccessible.addAll(page.inaccessible);
        yield ScanProgress(
          sourceId,
          filesProcessed: added + updated + unchanged,
        );
      }

      await _checkpoints.save(
        ScanCheckpoint(
          sourceId: sourceId,
          scanId: scanId,
          stage: ScanStage.finalizing,
          cursor: cursor,
        ),
      );
    }

    final removed = await _index.removeNotSeenIn(sourceId, scanId);
    await _checkpoints.clear(sourceId);
    yield ScanCompleted(
      ScanSummary(
        sourceId: sourceId,
        scanId: scanId,
        resumed: stored != null,
        added: added,
        updated: updated,
        unchanged: unchanged,
        removed: removed,
        inaccessible: inaccessible,
      ),
    );
  }
}
