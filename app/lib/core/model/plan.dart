import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/duplicate_group.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/plan_group.dart';
import 'package:file_organizer/core/model/plan_summary.dart';
import 'package:file_organizer/core/model/planned_operation.dart';
import 'package:meta/meta.dart';

/// A cleanup plan: what will be done, in which order, and why.
@immutable
final class Plan {
  /// Creates a plan.
  ///
  /// [operations] are kept in the given order, which is the execution order.
  /// [unresolved] are the files the rules could not classify; they stay
  /// where they are and have no operations. [duplicateGroups] are all
  /// duplicate groups found, including copies left alone because they are
  /// outside chaos zones.
  Plan({
    required Iterable<PlannedOperation> operations,
    Iterable<FileEntry> unresolved = const [],
    Iterable<DuplicateGroup> duplicateGroups = const [],
  }) : operations = List.unmodifiable(operations),
       unresolved = List.unmodifiable(unresolved),
       duplicateGroups = List.unmodifiable(duplicateGroups);

  /// A plan with nothing to do.
  static final Plan empty = Plan(operations: const []);

  /// All operations in execution order. Unmodifiable.
  final List<PlannedOperation> operations;

  /// Files left in place because the rules are not sure. Unmodifiable.
  final List<FileEntry> unresolved;

  /// All duplicate groups found. Copies without an operation (outside chaos
  /// zones) are shown to the user but never touched. Unmodifiable.
  final List<DuplicateGroup> duplicateGroups;

  /// Whether there is nothing to execute. Unresolved files do not count:
  /// planning again right after a completed cleanup yields an empty plan
  /// even if some files stay unresolved.
  bool get isEmpty => operations.isEmpty;

  /// Operations grouped by [PlannedOperation.groupKey]. Groups come in the
  /// order of their first operation; operations keep their order.
  List<PlanGroup> get groups {
    final byKey = <String, List<PlannedOperation>>{};
    for (final operation in operations) {
      (byKey[operation.groupKey] ??= []).add(operation);
    }
    return List.unmodifiable([
      for (final MapEntry(:key, :value) in byKey.entries)
        PlanGroup(key: key, operations: value),
    ]);
  }

  /// The operations the user approved, in execution order.
  List<PlannedOperation> get approvedOperations =>
      List.unmodifiable(operations.where((o) => o.approved));

  /// Totals over all operations.
  PlanSummary get summary => PlanSummary.of(operations);

  /// Totals over approved operations only.
  PlanSummary get approvedSummary => PlanSummary.of(approvedOperations);

  @override
  bool operator ==(Object other) =>
      other is Plan &&
      listEquals(other.operations, operations) &&
      listEquals(other.unresolved, unresolved) &&
      listEquals(other.duplicateGroups, duplicateGroups);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(operations),
    Object.hashAll(unresolved),
    Object.hashAll(duplicateGroups),
  );

  @override
  String toString() =>
      'Plan(${operations.length} operations, ${unresolved.length} unresolved, '
      '${duplicateGroups.length} duplicate groups)';
}
