import 'package:drift/native.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_clock.dart';
import '../support/fs/in_memory_file_source.dart';
import '../support/layout_fixtures.dart';
import '../support/scenarios.dart';
import '../support/sequential_id_generator.dart';

/// The whole cleanup on the SQLite repositories, as in the app.
void main() {
  late AppDatabase db;
  late InMemoryFileSource desktop;
  late InMemoryFileSource phone;
  final clock = FakeClock(autoAdvance: const Duration(seconds: 1));
  final ids = SequentialIdGenerator('d');

  CleanupWorkflow newWorkflow() => CleanupWorkflow(
    repositories: WorkflowRepositories(
      sources: DriftSourceRepository(db),
      rules: DriftRuleRepository(db),
      settings: DriftSettingsRepository(db),
      index: DriftFileIndexRepository(db),
      checkpoints: DriftScanCheckpointRepository(db),
      sessions: DriftSessionRepository(db),
      journal: DriftOperationJournal(db),
    ),
    fileSources: (id) => {desktop.sourceId: desktop, phone.sourceId: phone}[id],
    template: russianTemplate(),
    clock: clock,
    ids: ids,
    restoredLabel: 'восстановлено',
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    desktop = InMemoryFileSource(sourceId: const SourceId('desktop'))
      ..withTypicalDownloadFolder();
    phone = phoneStorage();
    for (final fs in [desktop, phone]) {
      await DriftSourceRepository(db).save(
        Source(
          id: fs.sourceId,
          kind: SourceKind.desktopFolder,
          displayName: fs.sourceId.value,
          capabilities: fs.capabilities,
          enabled: true,
        ),
      );
    }
  });

  test('button → plan → execution → undo', () async {
    final originalDesktop = desktop.snapshot();
    final originalPhone = phone.snapshot();
    final workflow = newWorkflow();

    await workflow.start();
    expect(workflow.state, isA<PlanReady>());
    await workflow.execute();
    expect(workflow.state, isA<Completed>());
    expect(desktop.isFile('Документы/notes.txt'), isTrue);

    await workflow.start();
    expect((workflow.state as PlanReady).isEmpty, isTrue);
    workflow.dismiss();

    final sessions = await DriftSessionRepository(db).all();
    for (final session in sessions) {
      await workflow.undoSession(session.id);
    }
    expect(originalDesktop.diff(desktop.snapshot()), isEmpty);
    expect(originalPhone.diff(phone.snapshot()), isEmpty);
  });

  test('a crash, a restart on the same database, then undo', () async {
    final original = desktop.snapshot();
    final workflow = newWorkflow();
    await workflow.start();
    desktop.crashOn(
      methods: {FsMethod.move},
      nth: 4,
      point: CrashPoint.afterEffect,
    );
    await expectLater(workflow.execute(), throwsA(isA<SimulatedCrash>()));
    desktop.clearFaults();

    final restarted = newWorkflow();
    await restarted.initialize();
    final interrupted = restarted.state as Interrupted;
    expect(interrupted.recovered.single.session.status, SessionStatus.failed);

    await restarted.undo();
    expect(restarted.state, isA<Reverted>());
    expect(original.diff(desktop.snapshot()), isEmpty);
  });
}
