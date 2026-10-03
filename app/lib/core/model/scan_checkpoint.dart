import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:meta/meta.dart';

/// Stage of a scan of one source.
enum ScanStage {
  /// Pages are being listed and indexed; the cursor marks the last indexed
  /// page.
  listing,

  /// Listing is complete; files not seen in this scan are being removed from
  /// the index.
  finalizing,
}

/// Where an unfinished scan of a source stopped, so it can resume.
@immutable
final class ScanCheckpoint {
  const ScanCheckpoint({
    required this.sourceId,
    required this.scanId,
    required this.stage,
    this.cursor,
  });

  final SourceId sourceId;

  /// The scan being resumed.
  final ScanId scanId;

  final ScanStage stage;

  /// Position after the last indexed page; `null` before the first page.
  final ScanCursor? cursor;

  @override
  bool operator ==(Object other) =>
      other is ScanCheckpoint &&
      other.sourceId == sourceId &&
      other.scanId == scanId &&
      other.stage == stage &&
      other.cursor == cursor;

  @override
  int get hashCode => Object.hash(sourceId, scanId, stage, cursor);

  @override
  String toString() =>
      'ScanCheckpoint($sourceId, $scanId, ${stage.name}, $cursor)';
}
