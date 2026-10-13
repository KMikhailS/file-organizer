import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/planner/planner.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/state/history/history_providers.dart';
import 'package:file_organizer/state/history/history_view.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_native.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/scenarios.dart';

/// Results, the history and undo by scope, the purged quarantine and the
/// interrupted cleanup (docs/stage2_android.md, 5.21), on a fake phone
/// whose files survive restarts of the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevice device;
  late InMemoryFileSource files;
  late ProviderContainer app;

  /// Starts the app (again): a new container over the same device.
  Future<void> launch() async {
    app = ProviderContainer(overrides: device.overrides);
    addTearDown(app.dispose);
    app.listen(cleanupViewProvider, (_, _) {});
    await app.read(appControllerProvider.notifier).start();
  }

  CleanupWorkflow workflow() => app.read(workflowProvider);
  CleanupActions actions() => app.read(cleanupActionsProvider);

  Future<CleanupView> view() async {
    for (
      var i = 0;
      i < 100 &&
          !identical(app.read(workflowStateProvider).value, workflow().state);
      i++
    ) {
      await pumpEventQueue();
    }
    return app.read(cleanupViewProvider);
  }

  Future<SessionDetail> detail(SessionId id) async {
    await pumpEventQueue();
    final found = await app.read(sessionDetailProvider(id).future);
    return found!;
  }

  Future<SessionId> cleanUp() async {
    await actions().plan();
    await actions().apply();
    final result = await view() as CleanupResult;
    actions().dismiss();
    return result.sessions.single;
  }

  setUp(() async {
    InMemoryFileSource? shared;
    device = FakeDevice(
      files: (source) =>
          files = shared ??= InMemoryFileSource(sourceId: source.id)
            ..withTypicalDownloadFolder(),
    )..access.allFiles = true;
    await device.fixFolderNames();
    await launch();
  });

  test('the history lists executed cleanups, newest first', () async {
    expect(await app.read(historyProvider.future), isEmpty);
    final first = await cleanUp();
    files.addFile('Download/later.pdf', text: 'later');
    final second = await cleanUp();
    await pumpEventQueue();
    final history = await app.read(historyProvider.future);
    expect([for (final s in history) s.id], [second, first]);
  });

  test('a session: groups without folders, files with their status', () async {
    final id = await cleanUp();
    final session = await detail(id);
    expect(session.session.status, SessionStatus.completed);
    expect(session.groups.first.kind, isA<DuplicatesGroup>());
    for (final group in session.groups) {
      for (final file in group.files) {
        expect(file.type, isNot(OperationType.mkdir));
        expect(file.status, OperationStatus.done);
        expect(file.undoable, isTrue);
      }
    }
    expect(
      session.undoable,
      session.groups.fold(0, (n, g) => n + g.files.length),
    );
  });

  test('undo one group, then one file, then the rest', () async {
    final id = await cleanUp();
    final documents = Planner.moveGroup(LogicalPath('Documents'));

    await actions().undoSession(id, groupKey: documents);
    expect(
      ((await view()) as CleanupResult).kind,
      ResultKind.partiallyReverted,
    );
    actions().dismiss();
    expect(files.isFile('Download/notes.txt'), isTrue);
    expect(files.isFile('Music/song.mp3'), isTrue);
    var session = await detail(id);
    final docs = session.groups.firstWhere((g) => g.key == documents);
    expect(docs.undoable, 0);
    expect(
      docs.files.every((f) => f.status == OperationStatus.reverted),
      isTrue,
    );

    final song = session.groups
        .expand((g) => g.files)
        .firstWhere((f) => f.from.value == 'Download/song.mp3');
    await actions().undoSession(id, operationId: song.operationId);
    await view();
    actions().dismiss();
    expect(files.isFile('Download/song.mp3'), isTrue);
    expect(files.isFile('Download/backup.zip'), isFalse);

    await actions().undoSession(id);
    expect(((await view()) as CleanupResult).kind, ResultKind.reverted);
    actions().dismiss();
    session = await detail(id);
    expect(session.session.status, SessionStatus.reverted);
    expect(session.undoable, 0);
  });

  test('undo the cleanup just done from its result', () async {
    await actions().plan();
    final before = files.snapshot().tree;
    await actions().apply();
    expect(((await view()) as CleanupResult).canUndo, isTrue);
    await actions().undoLast();
    final result = await view() as CleanupResult;
    expect(result.kind, ResultKind.reverted);
    expect(result.canUndo, isFalse);
    expect(result.totals.reverted, greaterThan(0));
    expect(files.snapshot().tree, before);
  });

  test('a failed operation shows as a problem of the result', () async {
    files.failOn(
      FileErrorKind.locked,
      methods: {FsMethod.move},
      path: 'Download/notes.txt',
    );
    await actions().plan();
    await actions().apply();
    final result = await view() as CleanupResult;
    expect(result.totals.failed, 1);
    final problems = await app.read(
      sessionProblemsProvider(result.sessions.single).future,
    );
    expect(problems.single.path.value, 'Download/notes.txt');
    expect(problems.single.problem, isA<FileSystemError>());
    expect(problems.single.needsAttention, isFalse);
  });

  test('a purged quarantine: marked, never undoable; undo brings back the '
      'rest', () async {
    await DriftSettingsRepository(device.database).save(
      (await DriftSettingsRepository(
        device.database,
      ).load()).copyWith(quarantineRetention: Settings.minQuarantineRetention),
    );
    final id = await cleanUp();
    device.clock.advance(const Duration(days: 2));
    await launch();

    final session = await detail(id);
    final duplicates = session.groups.first;
    expect(duplicates.kind, isA<DuplicatesGroup>());
    expect(duplicates.files.every((f) => f.purged && !f.undoable), isTrue);
    expect(session.purged, duplicates.files.length);

    await actions().undoSession(id);
    final result = await view() as CleanupResult;
    expect(result.kind, ResultKind.partiallyReverted);
    expect(result.totals.revertSkipped, duplicates.files.length);
    expect(files.isFile('Download/notes.txt'), isTrue);
  });

  group('an interrupted cleanup', () {
    Future<InterruptedCleanup> interrupt({bool loseFile = false}) async {
      files.crashOn(
        methods: {FsMethod.move},
        path: 'Download/notes.txt',
        point: CrashPoint.afterEffect,
      );
      await actions().plan();
      await expectLater(actions().apply(), throwsA(isA<SimulatedCrash>()));
      files.clearFaults();
      if (loseFile) {
        // Gone from its new place while the app was dead.
        files.removeExternally('Documents/notes.txt');
      }
      await launch();
      return await view() as InterruptedCleanup;
    }

    test('is found at start: what recovery sorted out', () async {
      final interrupted = await interrupt();
      expect(interrupted.sessions, 1);
      expect(interrupted.operations, greaterThan(0));
      expect(interrupted.problems, isEmpty);
      expect(interrupted.unavailable, 0);
      expect(files.isFile('Documents/notes.txt'), isTrue);
    });

    test('needs attention comes before an ordinary failure', () async {
      // Archives are moved before Documents: this failure comes first in
      // the journal.
      files.failOn(
        FileErrorKind.locked,
        methods: {FsMethod.move},
        path: 'Download/backup.zip',
      );
      await interrupt(loseFile: true);
      final session = (await app.read(historyProvider.future)).single;
      final problems = await app.read(
        sessionProblemsProvider(session.id).future,
      );
      expect(
        [for (final p in problems) p.path.value],
        ['Download/notes.txt', 'Download/backup.zip'],
      );
      expect(problems.first.needsAttention, isTrue);
      expect(problems.last.needsAttention, isFalse);
    });

    test('a file lost meanwhile needs attention, and comes first', () async {
      final interrupted = await interrupt(loseFile: true);
      expect(interrupted.problems.first.needsAttention, isTrue);
      expect(interrupted.problems.first.path.value, 'Download/notes.txt');
    });

    test('"undo it" brings the files back', () async {
      await interrupt();
      await actions().undoLast();
      expect(((await view()) as CleanupResult).kind, ResultKind.reverted);
      expect(files.isFile('Download/notes.txt'), isTrue);
      expect(files.isFile('Documents/notes.txt'), isFalse);
    });

    test('"finish the cleanup" plans what is left', () async {
      await interrupt();
      await actions().plan();
      final review = await view() as PlanReview;
      final planned = [
        for (final g in review.sources.single.groups)
          ...g.files.map((f) => f.from.value),
      ];
      expect(planned, isNot(contains('Download/notes.txt')));
      expect(planned, contains('Download/song.mp3'));
    });

    test('"not now" goes home; the session waits in the history', () async {
      await interrupt();
      actions().dismiss();
      expect(await view(), isA<AtHome>());
      final history = await app.read(historyProvider.future);
      expect(history.single.status, SessionStatus.failed);
      expect((await detail(history.single.id)).undoable, greaterThan(0));
    });
  });
}
