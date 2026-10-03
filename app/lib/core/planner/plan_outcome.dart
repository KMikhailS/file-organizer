import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/plan.dart';
import 'package:file_organizer/core/planner/plan_violation.dart';
import 'package:meta/meta.dart';

/// Result of planning.
@immutable
sealed class PlanOutcome {
  const PlanOutcome(this.plan);

  /// The plan as built (for an invalid one: for diagnostics only, never to
  /// execute).
  final Plan plan;
}

/// A valid plan, ready for review.
final class PlanReady extends PlanOutcome {
  const PlanReady(super.plan);

  @override
  bool operator ==(Object other) => other is PlanReady && other.plan == plan;

  @override
  int get hashCode => plan.hashCode;

  @override
  String toString() => 'PlanReady($plan)';
}

/// The plan broke a safety rule. It must not be executed.
final class PlanInvalid extends PlanOutcome {
  PlanInvalid(super.plan, Iterable<PlanViolation> violations)
    : violations = List.unmodifiable(violations);

  final List<PlanViolation> violations;

  @override
  bool operator ==(Object other) =>
      other is PlanInvalid &&
      other.plan == plan &&
      listEquals(other.violations, violations);

  @override
  int get hashCode => Object.hash(plan, Object.hashAll(violations));

  @override
  String toString() => 'PlanInvalid($violations)';
}
