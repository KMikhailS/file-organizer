import 'package:file_organizer/core/model/planned_operation.dart';
import 'package:meta/meta.dart';

/// Totals of a set of planned operations.
@immutable
final class PlanSummary {
  const PlanSummary({required this.fileCount, required this.reclaimableBytes});

  /// Sums up [operations].
  factory PlanSummary.of(Iterable<PlannedOperation> operations) {
    var files = 0;
    var bytes = 0;
    for (final operation in operations) {
      if (operation.type.actsOnFile) {
        files++;
      }
      if (operation.type.removesFile) {
        bytes += operation.fingerprint!.size;
      }
    }
    return PlanSummary(fileCount: files, reclaimableBytes: bytes);
  }

  static const PlanSummary zero = PlanSummary(
    fileCount: 0,
    reclaimableBytes: 0,
  );

  /// Number of files the operations act on (folders created are not
  /// counted).
  final int fileCount;

  /// Bytes freed once quarantined or album-marked duplicates are removed.
  final int reclaimableBytes;

  @override
  bool operator ==(Object other) =>
      other is PlanSummary &&
      other.fileCount == fileCount &&
      other.reclaimableBytes == reclaimableBytes;

  @override
  int get hashCode => Object.hash(fileCount, reclaimableBytes);

  @override
  String toString() =>
      'PlanSummary(files: $fileCount, reclaimableBytes: $reclaimableBytes)';
}
