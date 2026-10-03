import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:meta/meta.dart';

/// Outcome of a completed scan of one source.
///
/// The counts cover the pages listed in this run; a resumed scan does not
/// recount pages indexed before the interruption.
@immutable
final class ScanSummary {
  ScanSummary({
    required this.sourceId,
    required this.scanId,
    required this.resumed,
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.removed,
    required Iterable<LogicalPath> inaccessible,
  }) : inaccessible = List.unmodifiable(inaccessible);

  final SourceId sourceId;

  final ScanId scanId;

  /// Whether this run continued an interrupted scan.
  final bool resumed;

  /// Files new to the index.
  final int added;

  /// Files whose size or modification time changed; their hashes were
  /// dropped.
  final int updated;

  /// Files with the same size and modification time; their hashes were
  /// kept.
  final int unchanged;

  /// Index entries removed because their files were not seen (deleted,
  /// moved away, now excluded or inaccessible).
  final int removed;

  /// Folders that could not be read. Unmodifiable.
  final List<LogicalPath> inaccessible;

  /// Files listed in this run.
  int get filesSeen => added + updated + unchanged;

  @override
  bool operator ==(Object other) =>
      other is ScanSummary &&
      other.sourceId == sourceId &&
      other.scanId == scanId &&
      other.resumed == resumed &&
      other.added == added &&
      other.updated == updated &&
      other.unchanged == unchanged &&
      other.removed == removed &&
      listEquals(other.inaccessible, inaccessible);

  @override
  int get hashCode => Object.hash(
    sourceId,
    scanId,
    resumed,
    added,
    updated,
    unchanged,
    removed,
    Object.hashAll(inaccessible),
  );

  @override
  String toString() =>
      'ScanSummary($sourceId, $scanId, resumed: $resumed, added: $added, '
      'updated: $updated, unchanged: $unchanged, removed: $removed, '
      'inaccessible: $inaccessible)';
}
