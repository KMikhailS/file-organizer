import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/scan/scan_summary.dart';
import 'package:meta/meta.dart';

/// Progress and outcome of a scan. A scan stream ends with either
/// [ScanCompleted] or [ScanFailed].
@immutable
sealed class ScanEvent {
  const ScanEvent(this.sourceId);

  final SourceId sourceId;
}

/// A page was indexed.
final class ScanProgress extends ScanEvent {
  const ScanProgress(super.sourceId, {required this.filesProcessed});

  /// Files indexed so far in this run.
  final int filesProcessed;

  @override
  bool operator ==(Object other) =>
      other is ScanProgress &&
      other.sourceId == sourceId &&
      other.filesProcessed == filesProcessed;

  @override
  int get hashCode => Object.hash(sourceId, filesProcessed);

  @override
  String toString() => 'ScanProgress($sourceId, $filesProcessed files)';
}

/// The scan finished and the index matches the source.
final class ScanCompleted extends ScanEvent {
  ScanCompleted(this.summary) : super(summary.sourceId);

  final ScanSummary summary;

  @override
  bool operator ==(Object other) =>
      other is ScanCompleted && other.summary == summary;

  @override
  int get hashCode => summary.hashCode;

  @override
  String toString() => 'ScanCompleted($summary)';
}

/// The source could not be listed. The checkpoint is kept, so the next scan
/// resumes where this one stopped.
final class ScanFailed extends ScanEvent {
  const ScanFailed(
    super.sourceId, {
    required this.error,
    required this.filesProcessed,
  });

  final FileError error;

  /// Files indexed in this run before the failure.
  final int filesProcessed;

  @override
  bool operator ==(Object other) =>
      other is ScanFailed &&
      other.sourceId == sourceId &&
      other.error == error &&
      other.filesProcessed == filesProcessed;

  @override
  int get hashCode => Object.hash(sourceId, error, filesProcessed);

  @override
  String toString() => 'ScanFailed($sourceId, $error)';
}
