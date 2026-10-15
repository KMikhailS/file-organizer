import 'package:file_organizer/core/classify/builtin_rules.dart';
import 'package:file_organizer/core/classify/rule_classifier.dart';
import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/session_stats.dart';
import 'package:file_organizer/core/planner/planner.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';

/// The cleanup screens' view of [state] (`null` before the first state).
/// [cancelling]: "Cancel" was asked for and the work has not stopped yet.
CleanupView cleanupViewOf(WorkflowState? state, {bool cancelling = false}) =>
    switch (state) {
      null || Idle() => const AtHome(),
      Finished(:final sessions) => CleanupResult(
        kind: switch (state) {
          Completed() => ResultKind.completed,
          Cancelled() => ResultKind.cancelled,
          Reverted() => ResultKind.reverted,
          PartiallyReverted() => ResultKind.partiallyReverted,
        },
        sessions: sessions.map((s) => s.id),
        totals: addUp(sessions.map((s) => s.stats)),
      ),
      Scanning(:final filesProcessed, :final sourceIndex, :final sourceCount) =>
        InProgress(
          stage: ProgressStage.scanning,
          done: filesProcessed,
          total: 0,
          sourceIndex: sourceIndex,
          sourceCount: sourceCount,
          cancelling: cancelling,
        ),
      Analyzing(
        :final sizesDone,
        :final sizesTotal,
        :final sourceIndex,
        :final sourceCount,
      ) =>
        InProgress(
          stage: ProgressStage.analyzing,
          done: sizesDone,
          total: sizesTotal,
          sourceIndex: sourceIndex,
          sourceCount: sourceCount,
          cancelling: cancelling,
        ),
      Executing(:final progress, :final sourceIndex, :final sourceCount) =>
        InProgress(
          stage: ProgressStage.executing,
          done: progress?.done ?? 0,
          total: progress?.total ?? 0,
          sourceIndex: sourceIndex,
          sourceCount: sourceCount,
          cancelling: cancelling,
        ),
      Undoing(:final operationsProcessed) => InProgress(
        stage: ProgressStage.undoing,
        done: operationsProcessed,
        total: 0,
        sourceIndex: 0,
        sourceCount: 1,
        cancelling: cancelling,
      ),
      PlanReady() => _review(state),
      Failed(:final reason) => PlanFailed(reason),
      Interrupted(:final recovered, :final unavailable) => InterruptedCleanup(
        sessions: recovered.length,
        operations: recovered.fold(0, (n, r) => n + r.recovered.length),
        problems: problemsOf([for (final r in recovered) ...r.recovered]),
        unavailable: unavailable.length,
      ),
    };

PlanReview _review(PlanReady ready) {
  final summary = ready.approvedSummary;
  return PlanReview(
    sources: ready.plans.map(_source),
    unavailableSources: ready.unavailable,
    approvedFiles: summary.fileCount,
    approvedBytes: summary.reclaimableBytes,
  );
}

SourcePlanView _source(SourcePlan sourcePlan) {
  final plan = sourcePlan.plan;
  // Groups hold the plan's own operation objects: their indexes by
  // identity, in one pass (a plan may have tens of thousands).
  final indexes = Map<Object, int>.identity();
  for (var i = 0; i < plan.operations.length; i++) {
    indexes[plan.operations[i]] = i;
  }
  final groups = <PlanGroupView>[];
  final quarantined = <LogicalPath>{};
  for (final group in plan.groups) {
    final files = <OperationView>[
      for (final operation in group.operations)
        if (operation.type.actsOnFile)
          OperationView(
            index: indexes[operation]!,
            type: operation.type,
            from: operation.fromPath!,
            to: operation.type == OperationType.move ? operation.toPath : null,
            reason: operation.reason,
            approved: operation.approved,
            size: operation.fingerprint?.size ?? 0,
            media: isMediaFile(operation.fromPath!),
          ),
    ];
    if (files.isEmpty) {
      continue;
    }
    if (group.key == Planner.duplicatesGroup) {
      quarantined.addAll(files.map((f) => f.from));
    }
    groups.add(
      PlanGroupView(
        key: group.key,
        kind: groupKind(group.key),
        bytes: group.summary.reclaimableBytes,
        files: files,
      ),
    );
  }
  // Unresolved files never matched a user rule: the built-in rules give
  // the reason they stay.
  final rules = RuleClassifier();
  return SourcePlanView(
    source: sourcePlan.source,
    groups: groups,
    unresolved: [
      for (final file in plan.unresolved)
        UnresolvedFile(
          path: file.path,
          size: file.size,
          reason: rules.classifyFile(file).reason,
        ),
    ],
    untouchedCopies: [
      for (final group in plan.duplicateGroups)
        for (final copy in group.extras)
          if (!quarantined.contains(copy.path)) copy,
    ].length,
    inaccessibleFolders: sourcePlan.scan.inaccessible,
    unhashedFiles: sourcePlan.unhashed.map((skip) => skip.path),
  );
}

/// The kind of the plan group with [key] (`Planner.duplicatesGroup` or
/// `Planner.moveGroup`).
PlanGroupKind groupKind(String key) {
  if (key == Planner.duplicatesGroup) {
    return const DuplicatesGroup();
  }
  const prefix = 'move:';
  if (key.startsWith(prefix)) {
    return MoveGroup(LogicalPath(key.substring(prefix.length)));
  }
  throw ArgumentError.value(key, 'key', 'not a group key of the planner');
}

final Set<String> _mediaExtensions = {
  ...?BuiltinRules.extensions[Category.photos],
  ...?BuiltinRules.extensions[Category.videos],
  ...BuiltinRules.screenshotExtensions,
};

/// Whether the file at [path] is an image or a video by its extension.
bool isMediaFile(LogicalPath path) {
  final name = path.value.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot > 0 &&
      _mediaExtensions.contains(name.substring(dot + 1).toLowerCase());
}

/// The statistics of several sessions added up.
SessionStats addUp(Iterable<SessionStats> all) {
  var total = 0, done = 0, failed = 0, skipped = 0;
  var reverted = 0, revertSkipped = 0, removedBytes = 0;
  for (final stats in all) {
    total += stats.total;
    done += stats.done;
    failed += stats.failed;
    skipped += stats.skipped;
    reverted += stats.reverted;
    revertSkipped += stats.revertSkipped;
    removedBytes += stats.removedBytes;
  }
  return SessionStats(
    total: total,
    done: done,
    failed: failed,
    skipped: skipped,
    reverted: reverted,
    revertSkipped: revertSkipped,
    removedBytes: removedBytes,
  );
}

/// The problems among [operations] (an error that is still current:
/// failed, skipped, or not undone), "needs attention" first, otherwise in
/// order.
///
/// An operation a crash stopped before it took effect is no problem: its
/// file is where it was, and finishing the cleanup plans it again. A crash
/// leaves a whole journal batch of them (`docs/stage2_android.md`, 5.27).
List<ProblemView> problemsOf(Iterable<Operation> operations) {
  final problems = [
    for (final op in operations)
      if (op.status.hasError &&
          op.error != null &&
          op.error is! InterruptedOperation)
        ProblemView(
          type: op.type,
          path: op.fromPath ?? op.toPath!,
          problem: op.error!,
        ),
  ];
  return [
    ...problems.where((p) => p.needsAttention),
    ...problems.where((p) => !p.needsAttention),
  ];
}
