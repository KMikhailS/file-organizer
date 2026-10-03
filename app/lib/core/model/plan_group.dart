import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/plan_summary.dart';
import 'package:file_organizer/core/model/planned_operation.dart';
import 'package:meta/meta.dart';

/// Operations of a plan that share a group key, for example "Duplicates" or
/// "To Photos / 2024".
@immutable
final class PlanGroup {
  /// Creates a group.
  ///
  /// Throws [ArgumentError] if [operations] is empty or contains an
  /// operation with another group key.
  factory PlanGroup({
    required String key,
    required Iterable<PlannedOperation> operations,
  }) {
    final list = List<PlannedOperation>.unmodifiable(operations);
    if (list.isEmpty) {
      throw ArgumentError.value(list, 'operations', 'must not be empty');
    }
    if (list.any((o) => o.groupKey != key)) {
      throw ArgumentError.value(list, 'operations', 'must have group key $key');
    }
    return PlanGroup._(key, list);
  }

  const PlanGroup._(this.key, this.operations);

  final String key;

  /// The operations in execution order. Unmodifiable.
  final List<PlannedOperation> operations;

  PlanSummary get summary => PlanSummary.of(operations);

  @override
  bool operator ==(Object other) =>
      other is PlanGroup &&
      other.key == key &&
      listEquals(other.operations, operations);

  @override
  int get hashCode => Object.hash(key, Object.hashAll(operations));

  @override
  String toString() => 'PlanGroup($key, ${operations.length} operations)';
}
