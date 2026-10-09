import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// What the temporary work screen shows about the workflow, and which of
/// its buttons work. TEMPORARY: the screens of tasks 13–14 replace it.
@immutable
final class CleanupStatus {
  const CleanupStatus({
    required this.text,
    this.canPlan = false,
    this.canCancel = false,
    this.canDismiss = false,
    this.atHome = false,
  });

  final String text;
  final bool canPlan;
  final bool canCancel;
  final bool canDismiss;

  /// The workflow neither works nor holds a result: the home screen shows,
  /// not the temporary work screen.
  final bool atHome;

  static CleanupStatus of(WorkflowState state) => switch (state) {
    Idle() => const CleanupStatus(text: 'Ready', canPlan: true, atHome: true),
    Interrupted(:final recovered, :final unavailable) => CleanupStatus(
      text:
          'Interrupted cleanup: ${recovered.length} recovered, '
          '${unavailable.length} unavailable',
      canPlan: true,
      canDismiss: true,
    ),
    Scanning(:final filesProcessed) => CleanupStatus(
      text: 'Scanning: $filesProcessed files',
      canCancel: true,
    ),
    Analyzing(:final sizesDone, :final sizesTotal) => CleanupStatus(
      text: 'Looking for duplicates: $sizesDone of $sizesTotal',
      canCancel: true,
    ),
    PlanReady(:final plans) => CleanupStatus(
      text:
          'Plan ready: ${plans.fold(0, (n, p) => n + p.plan.operations.length)}'
          ' operations (not applied in this build)',
      canDismiss: true,
    ),
    Executing() => const CleanupStatus(text: 'Tidying up', canCancel: true),
    Undoing() => const CleanupStatus(text: 'Undoing', canCancel: true),
    Finished() => CleanupStatus(
      text: 'Finished: ${state.runtimeType}',
      canPlan: true,
      atHome: true,
    ),
    Failed(:final reason) => CleanupStatus(
      text: 'Failed: $reason',
      canPlan: true,
      canDismiss: true,
    ),
  };
}

/// The status of the workflow for the temporary work screen.
final cleanupStatusProvider = Provider<CleanupStatus>(
  (ref) => switch (ref.watch(workflowStateProvider).value) {
    final state? => CleanupStatus.of(state),
    null => const CleanupStatus(text: 'Starting', atHome: true),
  },
);

/// The commands of the home and temporary work screens. There is no
/// "apply" until task 13: this build never changes files.
final class CleanupActions {
  const CleanupActions(this._workflow);

  final CleanupWorkflow _workflow;

  /// Scans and plans (nothing is changed).
  Future<void> plan() => _workflow.start();

  void cancel() => _workflow.cancel();

  void dismiss() => _workflow.dismiss();
}

final cleanupActionsProvider = Provider<CleanupActions>(
  (ref) => CleanupActions(ref.watch(workflowProvider)),
);
