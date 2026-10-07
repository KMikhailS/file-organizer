import 'dart:async';

import 'package:file_organizer/core/classify/classification_pipeline.dart';
import 'package:file_organizer/core/classify/rule_classifier.dart';
import 'package:file_organizer/core/dedupe/dedupe_event.dart';
import 'package:file_organizer/core/dedupe/duplicate_finder.dart';
import 'package:file_organizer/core/executor/executor.dart';
import 'package:file_organizer/core/layout/layout_template.dart';
import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/plan.dart';
import 'package:file_organizer/core/model/session_status.dart';
import 'package:file_organizer/core/planner/plan_outcome.dart' as planning;
import 'package:file_organizer/core/planner/planner.dart';
import 'package:file_organizer/core/ports/cancel_token.dart';
import 'package:file_organizer/core/ports/classifier.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_index_repository.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/id_generator.dart';
import 'package:file_organizer/core/ports/operation_journal.dart';
import 'package:file_organizer/core/ports/rule_repository.dart';
import 'package:file_organizer/core/ports/scan_checkpoint_repository.dart';
import 'package:file_organizer/core/ports/session_repository.dart';
import 'package:file_organizer/core/ports/settings_repository.dart';
import 'package:file_organizer/core/ports/source_repository.dart';
import 'package:file_organizer/core/quarantine/quarantine_purger.dart';
import 'package:file_organizer/core/recovery/recovery.dart';
import 'package:file_organizer/core/scan/scan_event.dart';
import 'package:file_organizer/core/scan/scan_summary.dart';
import 'package:file_organizer/core/scan/scanner.dart';
import 'package:file_organizer/core/undo/undo_service.dart';
import 'package:file_organizer/core/undo/undo_types.dart';
import 'package:file_organizer/core/workflow/workflow_state.dart';
import 'package:file_organizer/core/zones/zone_map.dart';

/// The repositories the workflow works with.
final class WorkflowRepositories {
  const WorkflowRepositories({
    required this.sources,
    required this.rules,
    required this.settings,
    required this.index,
    required this.checkpoints,
    required this.sessions,
    required this.journal,
  });

  final SourceRepository sources;
  final RuleRepository rules;
  final SettingsRepository settings;
  final FileIndexRepository index;
  final ScanCheckpointRepository checkpoints;
  final SessionRepository sessions;
  final OperationJournal journal;
}

/// The single entry point for the UI: the cleanup state machine.
///
/// - [initialize] recovers sessions a crash interrupted and purges the
///   expired quarantine; then the state is [Idle] or [Interrupted].
/// - [start] scans every enabled source, finds duplicates, classifies and
///   plans: [Scanning] → [Analyzing] → [PlanReady] (or [Failed]). From
///   [Interrupted] it is "finish the job": a new plan of what is left.
/// - In [PlanReady] the user approves groups or operations, then [execute]
///   runs one session per source: [Executing] → [Completed] or
///   [Cancelled]. [dismiss] declines the plan.
/// - [undo] undoes the sessions of the last run, [undoSession] any session
///   from the history: [Undoing] → [Reverted] or [PartiallyReverted].
/// - [cancel] stops what is running: scanning and analysis go back to
///   [Idle] (the scan resumes next time), execution and undo stop after
///   the current operation.
///
/// Only one command runs at a time. A command that does not fit the current
/// state throws [StateError].
final class CleanupWorkflow {
  CleanupWorkflow({
    required WorkflowRepositories repositories,
    required this._fileSources,
    required this._template,
    required Clock clock,
    required IdGenerator ids,
    required String restoredLabel,
    this._ai,
  }) : _repos = repositories,
       _ids = ids,
       _executor = Executor(
         journal: repositories.journal,
         sessions: repositories.sessions,
         clock: clock,
         ids: ids,
       ),
       _undo = UndoService(
         journal: repositories.journal,
         sessions: repositories.sessions,
         clock: clock,
         restoredLabel: restoredLabel,
       ),
       _recovery = Recovery(
         journal: repositories.journal,
         sessions: repositories.sessions,
         clock: clock,
         ids: ids,
       ),
       _purger = QuarantinePurger(
         journal: repositories.journal,
         sessions: repositories.sessions,
         settings: repositories.settings,
         clock: clock,
       );

  final WorkflowRepositories _repos;

  /// The platform's file source for a source id, or `null` if it cannot be
  /// opened now (permission revoked, drive unplugged, ...).
  final FileSource? Function(SourceId id) _fileSources;

  final LayoutTemplate _template;
  final IdGenerator _ids;
  final Classifier? _ai;
  final Executor _executor;
  final UndoService _undo;
  final Recovery _recovery;
  final QuarantinePurger _purger;

  final StreamController<WorkflowState> _states =
      StreamController<WorkflowState>.broadcast(sync: true);
  WorkflowState _state = const Idle();
  bool _initialized = false;
  bool _commandRunning = false;
  bool _cancelRequested = false;

  /// Stops hashing inside a file when [cancel] is called during analysis.
  CancelToken _hashing = CancelToken();
  ExecutionRun? _execution;
  UndoRun? _undoRun;

  /// Sessions of the last run, for [undo].
  List<CleanupSession> _lastSessions = const [];

  WorkflowState get state => _state;

  /// The current state, then every change. Each listener gets the current
  /// state first.
  Stream<WorkflowState> get states => Stream.multi((controller) {
    controller.add(_state);
    final subscription = _states.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  }, isBroadcast: true);

  /// Recovers interrupted sessions and purges the expired quarantine. Runs
  /// once, before the first [start]; [start] calls it if needed.
  Future<void> initialize() => _command('initialize', {Idle}, () async {
    await _initialize();
  });

  /// Plans a cleanup of all enabled sources.
  Future<void> start() => _command(
    'start',
    {
      Idle,
      Interrupted,
      Completed,
      Cancelled,
      Reverted,
      PartiallyReverted,
      Failed,
    },
    () async {
      if (!_initialized) {
        await _initialize();
        if (_state is Interrupted) {
          return;
        }
      }
      await _plan();
    },
  );

  /// Approves or declines every operation of [groupKey] in the plan of
  /// [sourceId]. Folders follow the moves into them.
  void setGroupApproval(
    SourceId sourceId,
    String groupKey, {
    required bool approved,
  }) => _editPlan(sourceId, (plan) {
    if (!plan.operations.any((o) => o.groupKey == groupKey)) {
      throw ArgumentError.value(groupKey, 'groupKey', 'not in the plan');
    }
    return Plan(
      operations: [
        for (final op in plan.operations)
          op.groupKey == groupKey && op.type != OperationType.mkdir
              ? op.withApproved(approved: approved)
              : op,
      ],
      unresolved: plan.unresolved,
      duplicateGroups: plan.duplicateGroups,
    );
  });

  /// Approves or declines the operation at [index] of the plan of
  /// [sourceId]. Folders cannot be toggled: they follow the moves.
  void setOperationApproval(
    SourceId sourceId,
    int index, {
    required bool approved,
  }) => _editPlan(sourceId, (plan) {
    RangeError.checkValidIndex(index, plan.operations, 'index');
    if (plan.operations[index].type == OperationType.mkdir) {
      throw ArgumentError.value(index, 'index', 'folders follow the moves');
    }
    return Plan(
      operations: [
        for (var i = 0; i < plan.operations.length; i++)
          i == index
              ? plan.operations[i].withApproved(approved: approved)
              : plan.operations[i],
      ],
      unresolved: plan.unresolved,
      duplicateGroups: plan.duplicateGroups,
    );
  });

  /// Executes the approved operations, one session per source.
  Future<void> execute() => _command('execute', {PlanReady}, _execute);

  /// Undoes the sessions of the last run (or the interrupted ones), last
  /// first.
  Future<void> undo() => _command(
    'undo',
    {Completed, Cancelled, Interrupted, PartiallyReverted},
    () => _undoSessions(
      _lastSessions.map((s) => s.id).toList().reversed,
      const WholeSession(),
    ),
  );

  /// Undoes [scope] of any finished session, for the history screen.
  Future<void> undoSession(
    SessionId sessionId, {
    UndoScope scope = const WholeSession(),
  }) => _command('undoSession', {
    Idle,
    Completed,
    Cancelled,
    Reverted,
    PartiallyReverted,
    Failed,
  }, () => _undoSessions([sessionId], scope));

  /// Stops what is running. Does nothing when nothing runs.
  void cancel() {
    if (!_state.isBusy) {
      return;
    }
    _cancelRequested = true;
    _hashing.cancel();
    _execution?.cancel();
    _undoRun?.cancel();
  }

  /// Declines the plan or acknowledges a result; back to [Idle].
  void dismiss() {
    if (_commandRunning || _state is Idle || _state.isBusy) {
      throw StateError('Cannot dismiss in $_state');
    }
    _emit(const Idle());
  }

  // ------------------------------------------------------------- commands

  Future<void> _command(
    String name,
    Set<Type> allowed,
    Future<void> Function() body,
  ) async {
    if (_commandRunning) {
      throw StateError('Cannot $name: another command is running');
    }
    if (!allowed.contains(_state.runtimeType)) {
      throw StateError('Cannot $name in $_state');
    }
    if (name == 'initialize' && _initialized) {
      throw StateError('Already initialized');
    }
    _commandRunning = true;
    _cancelRequested = false;
    _hashing = CancelToken();
    try {
      await body();
    } on Exception catch (e) {
      // Storage or other expected failures: report, do not crash the UI.
      _emit(Failed('$name failed: $e'));
    } finally {
      _commandRunning = false;
      _execution = null;
      _undoRun = null;
    }
  }

  Future<void> _initialize() async {
    _initialized = true;
    final recovered = <RecoveryResult>[];
    final unavailable = <SessionId>[];
    for (final session in await _recovery.interruptedSessions()) {
      final sourceId = await _recovery.sourceOf(session.id);
      final source = sourceId == null ? null : _fileSources(sourceId);
      if (sourceId != null && source == null) {
        unavailable.add(session.id);
        continue;
      }
      recovered.add(await _recovery.recover(session.id, source: source));
    }

    final available = <SourceId, FileSource>{};
    for (final source in await _repos.sources.all()) {
      final fileSource = _fileSources(source.id);
      if (fileSource != null) {
        available[source.id] = fileSource;
      }
    }
    await _purger.purgeExpired(available);

    if (recovered.isNotEmpty || unavailable.isNotEmpty) {
      _lastSessions = [for (final r in recovered) r.session];
      _emit(Interrupted(recovered, unavailable: unavailable));
    }
  }

  Future<void> _plan() async {
    final sources = [
      for (final s in await _repos.sources.all())
        if (s.enabled) s,
    ];
    final plans = <SourcePlan>[];
    final unavailable = <SourceId>[];
    final classifier = ClassificationPipeline(
      rules: RuleClassifier(
        userRules: await _repos.rules.classificationRules(),
      ),
      ai: _ai,
    );
    final planner = Planner(classifier: classifier, template: _template);

    for (var i = 0; i < sources.length; i++) {
      final source = sources[i];
      final fs = _fileSources(source.id);
      if (fs == null) {
        unavailable.add(source.id);
        continue;
      }
      final overrides = await _repos.rules.zoneOverrides(source.id);
      final config = ZoneConfig(
        targetFolders: _template.targetFolders,
        appFolders: fs.appFolders,
      );

      // Scan.
      _emit(
        Scanning(
          sourceId: source.id,
          sourceIndex: i,
          sourceCount: sources.length,
          filesProcessed: 0,
        ),
      );
      final pathZones = ZoneMap(
        sourceId: source.id,
        config: config,
        overrides: overrides,
      );
      ScanSummary? summary;
      await for (final event in Scanner(
        index: _repos.index,
        checkpoints: _repos.checkpoints,
        ids: _ids,
      ).scan(fs, skipFolder: pathZones.skipFolder)) {
        switch (event) {
          case ScanProgress(:final filesProcessed):
            _emit(
              Scanning(
                sourceId: source.id,
                sourceIndex: i,
                sourceCount: sources.length,
                filesProcessed: filesProcessed,
              ),
            );
          case ScanCompleted(summary: final s):
            summary = s;
          case ScanFailed(:final error):
            _emit(Failed('Scanning ${source.displayName} failed: $error'));
            return;
        }
        if (_cancelRequested) {
          _emit(const Idle());
          return;
        }
      }
      if (summary == null) {
        throw StateError('scan of ${source.id} ended without a result');
      }

      // Analyze.
      final files = await _repos.index.bySource(source.id);
      final zones = ZoneMap(
        sourceId: source.id,
        config: config,
        overrides: overrides,
        files: files,
      );
      DedupeCompleted? dedupe;
      _emit(
        Analyzing(
          sourceId: source.id,
          sourceIndex: i,
          sourceCount: sources.length,
          sizesDone: 0,
          sizesTotal: 0,
        ),
      );
      await for (final event in DuplicateFinder(
        index: _repos.index,
      ).find(fs, zones, cancel: _hashing)) {
        switch (event) {
          case DedupeProgress(:final sizesDone, :final sizesTotal):
            _emit(
              Analyzing(
                sourceId: source.id,
                sourceIndex: i,
                sourceCount: sources.length,
                sizesDone: sizesDone,
                sizesTotal: sizesTotal,
              ),
            );
          case DedupeCompleted():
            dedupe = event;
        }
        if (_cancelRequested) {
          _emit(const Idle());
          return;
        }
      }

      if (_cancelRequested) {
        // The finder stopped inside a file without a result.
        _emit(const Idle());
        return;
      }
      switch (await planner.plan(
        source: fs,
        files: await _repos.index.bySource(source.id),
        zones: zones,
        duplicates: dedupe!.groups,
      )) {
        case planning.PlanReady(:final plan):
          plans.add(
            SourcePlan(
              source: source,
              plan: plan,
              scan: summary,
              unhashed: dedupe.skipped,
            ),
          );
        case planning.PlanInvalid(:final violations):
          _emit(
            Failed(
              'The plan for ${source.displayName} broke a safety rule: '
              '${violations.first}',
            ),
          );
          return;
      }
      if (_cancelRequested) {
        _emit(const Idle());
        return;
      }
    }
    _emit(PlanReady(plans, unavailable: unavailable));
  }

  Future<void> _execute() async {
    final ready = _state as PlanReady;
    final toRun = [
      for (final p in ready.plans)
        if (p.plan.approvedOperations.isNotEmpty) p,
    ];
    final sessions = <CleanupSession>[];
    var cancelled = false;

    for (var i = 0; i < toRun.length && !cancelled; i++) {
      final sourcePlan = toRun[i];
      final fs = _fileSources(sourcePlan.source.id);
      if (fs == null) {
        continue;
      }
      _emit(
        Executing(
          sourceId: sourcePlan.source.id,
          sourceIndex: i,
          sourceCount: toRun.length,
        ),
      );
      final run = _executor.start(fs, sourcePlan.plan);
      _execution = run;
      if (_cancelRequested) {
        run.cancel();
      }
      final subscription = run.progress.listen(
        (p) => _emit(
          Executing(
            sourceId: sourcePlan.source.id,
            sourceIndex: i,
            sourceCount: toRun.length,
            progress: p,
          ),
        ),
      );
      final session = await run.result;
      await subscription.cancel();
      sessions.add(session);
      cancelled = session.status == SessionStatus.cancelled;
    }

    _lastSessions = sessions;
    _emit(cancelled ? Cancelled(sessions) : Completed(sessions));
  }

  Future<void> _undoSessions(Iterable<SessionId> ids, UndoScope scope) async {
    final sessionIds = ids.toList();
    final updated = <SessionId, CleanupSession>{};
    var stopped = false;
    for (var i = 0; i < sessionIds.length && !stopped; i++) {
      final id = sessionIds[i];
      final sourceId = await _recovery.sourceOf(id);
      final fs = sourceId == null ? null : _fileSources(sourceId);
      if (fs == null && sourceId != null) {
        continue;
      }
      _emit(
        Undoing(
          sessionId: id,
          sessionIndex: i,
          sessionCount: sessionIds.length,
          operationsProcessed: 0,
        ),
      );
      // Without operations there is no source and nothing to put back; the
      // session just closes.
      final run = _undo.start(fs, id, scope: scope);
      _undoRun = run;
      if (_cancelRequested) {
        run.cancel();
      }
      var processed = 0;
      final subscription = run.progress.listen(
        (_) => _emit(
          Undoing(
            sessionId: id,
            sessionIndex: i,
            sessionCount: sessionIds.length,
            operationsProcessed: ++processed,
          ),
        ),
      );
      updated[id] = (await run.result).session;
      await subscription.cancel();
      stopped = _cancelRequested;
    }

    // Every session of the run stays listed, undone or not, so the next
    // undo picks up what is left.
    final all = <CleanupSession>[
      for (final id in sessionIds.reversed)
        updated[id] ?? (await _repos.sessions.byId(id))!,
    ];
    _lastSessions = all;
    final everythingReverted = all.every(
      (s) => s.status == SessionStatus.reverted,
    );
    _emit(everythingReverted ? Reverted(all) : PartiallyReverted(all));
  }

  void _editPlan(SourceId sourceId, Plan Function(Plan plan) edit) {
    final ready = _state;
    if (ready is! PlanReady || _commandRunning) {
      throw StateError('Approvals can only change in PlanReady, not $_state');
    }
    final index = ready.plans.indexWhere((p) => p.source.id == sourceId);
    if (index < 0) {
      throw ArgumentError.value(sourceId, 'sourceId', 'no plan for it');
    }
    final edited = _withFolderApprovals(edit(ready.plans[index].plan));
    _emit(
      PlanReady([
        for (var i = 0; i < ready.plans.length; i++)
          i == index ? ready.plans[i].withPlan(edited) : ready.plans[i],
      ], unavailable: ready.unavailable),
    );
  }

  /// A folder is approved exactly when an approved move goes into it.
  static Plan _withFolderApprovals(Plan plan) {
    final targets = [
      for (final op in plan.operations)
        if (op.type == OperationType.move && op.approved) op.toPath!,
    ];
    return Plan(
      operations: [
        for (final op in plan.operations)
          op.type == OperationType.mkdir
              ? op.withApproved(
                  approved: targets.any((t) => t.isWithin(op.toPath!)),
                )
              : op,
      ],
      unresolved: plan.unresolved,
      duplicateGroups: plan.duplicateGroups,
    );
  }

  void _emit(WorkflowState state) {
    _state = state;
    _states.add(state);
  }
}
