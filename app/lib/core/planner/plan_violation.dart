import 'package:file_organizer/core/model/planned_operation.dart';
import 'package:meta/meta.dart';

/// What a plan must never do.
enum ViolationKind {
  /// The target of a move or mkdir is taken (on disk, compared
  /// case-insensitively).
  overwrite,

  /// Two operations share a target.
  duplicateTarget,

  /// One file takes part in two operations.
  fileUsedTwice,

  /// The operation belongs to another source.
  leavesSource,

  /// The operation touches a file outside a chaos zone, or puts something
  /// outside the target folders.
  protectedZone,

  /// The source cannot do this operation.
  unsupported,

  /// The parent folder neither exists nor is created earlier in the plan.
  missingParent,
}

/// A broken rule in a plan: a bug in planning, never silently skipped.
@immutable
final class PlanViolation {
  const PlanViolation(this.kind, this.operation, this.message);

  final ViolationKind kind;

  final PlannedOperation operation;

  final String message;

  @override
  bool operator ==(Object other) =>
      other is PlanViolation &&
      other.kind == kind &&
      other.operation == operation &&
      other.message == message;

  @override
  int get hashCode => Object.hash(kind, operation, message);

  @override
  String toString() => 'PlanViolation(${kind.name}: $message; $operation)';
}
