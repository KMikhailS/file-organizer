import 'package:file_organizer/core/classify/classify.dart';
import 'package:file_organizer/core/dedupe/dedupe.dart';
import 'package:file_organizer/core/executor/execution.dart';
import 'package:file_organizer/core/layout/layout.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/planner/planning.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/core/quarantine/quarantine_purger.dart';
import 'package:file_organizer/core/recovery/recovery.dart';
import 'package:file_organizer/core/scan/scan.dart';
import 'package:file_organizer/core/undo/undo.dart';
import 'package:file_organizer/core/zones/zones.dart';

import 'fake_clock.dart';
import 'fs/in_memory_file_source.dart';
import 'layout_fixtures.dart';
import 'repositories/in_memory_repositories.dart';
import 'sequential_id_generator.dart';

/// Runs the pipeline the way the workflow will: scan → zones → duplicates →
/// plan, then execution and undo, with in-memory repositories.
class PipelineHarness {
  PipelineHarness(
    this.fs, {
    LayoutTemplate? template,
    Classifier? classifier,
    this.overrides = const [],
  }) : template = template ?? russianTemplate(),
       classifier = classifier ?? RuleClassifier();

  final InMemoryFileSource fs;
  final LayoutTemplate template;
  final Classifier classifier;
  final List<ZoneOverride> overrides;

  final InMemoryFileIndexRepository index = InMemoryFileIndexRepository();
  final InMemoryScanCheckpointRepository checkpoints =
      InMemoryScanCheckpointRepository();
  final SequentialIdGenerator ids = SequentialIdGenerator('scan');

  final InMemoryOperationJournal journal = InMemoryOperationJournal();
  final InMemorySessionRepository sessions = InMemorySessionRepository();
  final FakeClock clock = FakeClock(autoAdvance: const Duration(seconds: 1));
  final SequentialIdGenerator executionIds = SequentialIdGenerator('x');

  /// Label of files restored next to a taken place.
  static const String restoredLabel = 'восстановлено';

  late final Executor executor = Executor(
    journal: journal,
    sessions: sessions,
    clock: clock,
    ids: executionIds,
  );

  late final UndoService undoService = UndoService(
    journal: journal,
    sessions: sessions,
    clock: clock,
    restoredLabel: restoredLabel,
  );

  final InMemorySettingsRepository settings = InMemorySettingsRepository();

  late final Recovery recovery = Recovery(
    journal: journal,
    sessions: sessions,
    clock: clock,
    ids: executionIds,
  );

  late final QuarantinePurger purger = QuarantinePurger(
    journal: journal,
    sessions: sessions,
    settings: settings,
    clock: clock,
  );

  /// Zones of the last [plan] call.
  late ZoneMap zones;

  ZoneConfig get zoneConfig => ZoneConfig(
    targetFolders: template.targetFolders,
    appFolders: fs.appFolders,
  );

  /// Scans, finds duplicates and plans.
  Future<PlanOutcome> plan() async {
    final pathZones = ZoneMap(
      sourceId: fs.sourceId,
      config: zoneConfig,
      overrides: overrides,
    );
    await Scanner(
      index: index,
      checkpoints: checkpoints,
      ids: ids,
    ).scan(fs, skipFolder: pathZones.skipFolder).drain<void>();
    final files = await index.bySource(fs.sourceId);
    zones = ZoneMap(
      sourceId: fs.sourceId,
      config: zoneConfig,
      overrides: overrides,
      files: files,
    );
    final dedupe =
        (await DuplicateFinder(index: index).find(fs, zones).last)
            as DedupeCompleted;
    return Planner(classifier: classifier, template: template).plan(
      source: fs,
      files: await index.bySource(fs.sourceId),
      zones: zones,
      duplicates: dedupe.groups,
    );
  }

  /// Executes [plan] to the end.
  Future<CleanupSession> execute(Plan plan) => executor.start(fs, plan).result;

  /// Undoes [scope] of [sessionId] to the end.
  Future<UndoResult> undo(
    SessionId sessionId, {
    UndoScope scope = const WholeSession(),
  }) => undoService.start(fs, sessionId, scope: scope).result;

  /// The journal of [sessionId] in seq order.
  Future<List<Operation>> operations(SessionId sessionId) =>
      journal.bySession(sessionId);

  /// [plan], expecting a valid plan.
  Future<Plan> readyPlan() async => switch (await plan()) {
    PlanReady(:final plan) => plan,
    PlanInvalid(:final violations) => throw StateError('$violations'),
  };
}

/// Applies the approved operations of [plan] straight through the port, in
/// order, failing on the first error. A stand-in for the executor in
/// planner tests: no journal, no checks.
Future<void> applyPlan(InMemoryFileSource fs, Plan plan) async {
  const session = SessionId('apply');
  for (final op in plan.approvedOperations) {
    final result = switch (op.type) {
      OperationType.mkdir => await fs.mkdir(op.toPath!),
      OperationType.move => await fs.move(op.fromPath!, op.toPath!),
      OperationType.quarantine =>
        (await fs.quarantine(op.fromPath!, session)).isSuccess
            ? succeeded
            : FileFailure<void>.of(FileErrorKind.ioError, 'quarantine'),
      OperationType.addToAlbum => await fs.addToAlbum(op.fromPath!),
    };
    if (!result.isSuccess) {
      throw StateError('$op failed: $result');
    }
  }
}

/// One line per operation, for readable plan comparisons.
List<String> describe(Plan plan) => [
  for (final op in plan.operations)
    switch (op.type) {
      OperationType.mkdir => 'mkdir ${op.toPath}',
      OperationType.move => 'move ${op.fromPath} -> ${op.toPath}',
      OperationType.quarantine => 'quarantine ${op.fromPath}',
      OperationType.addToAlbum => 'addToAlbum ${op.fromPath}',
    },
];
