import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/layout_fixtures.dart';
import '../../support/repositories/in_memory_repositories.dart';
import '../../support/scenarios.dart';
import '../../support/sequential_id_generator.dart';

/// The app around the workflow: repositories, file sources, a clock.
/// [restart] builds a new workflow on the same data, as after a relaunch.
class _App {
  final repositories = WorkflowRepositories(
    sources: InMemorySourceRepository(),
    rules: InMemoryRuleRepository(),
    settings: InMemorySettingsRepository(),
    index: InMemoryFileIndexRepository(),
    checkpoints: InMemoryScanCheckpointRepository(),
    sessions: InMemorySessionRepository(),
    journal: InMemoryOperationJournal(),
  );
  final Map<SourceId, InMemoryFileSource> fileSources = {};
  final Set<SourceId> offline = {};
  final clock = FakeClock(autoAdvance: const Duration(seconds: 1));
  final ids = SequentialIdGenerator('w');
  final List<WorkflowState> states = [];

  late CleanupWorkflow workflow = _build();

  CleanupWorkflow _build() {
    final workflow = CleanupWorkflow(
      repositories: repositories,
      fileSources: (id) => offline.contains(id) ? null : fileSources[id],
      template: russianTemplate(),
      clock: clock,
      ids: ids,
      restoredLabel: 'восстановлено',
    );
    states.clear();
    workflow.states.listen(states.add);
    return workflow;
  }

  CleanupWorkflow restart() => workflow = _build();

  Future<InMemoryFileSource> add(
    InMemoryFileSource fs, {
    bool enabled = true,
    String name = 'Source',
  }) async {
    fileSources[fs.sourceId] = fs;
    await repositories.sources.save(
      Source(
        id: fs.sourceId,
        kind: SourceKind.desktopFolder,
        displayName: name,
        location: 'memory:${fs.sourceId.value}',
        capabilities: fs.capabilities,
        enabled: enabled,
      ),
    );
    return fs;
  }

  PlanReady get ready => workflow.state as PlanReady;

  SourcePlan planOf(InMemoryFileSource fs) =>
      ready.plans.singleWhere((p) => p.source.id == fs.sourceId);

  /// The kinds of states seen, without repeats in a row.
  List<Type> get stateKinds {
    final kinds = <Type>[];
    for (final s in states) {
      if (kinds.isEmpty || kinds.last != s.runtimeType) {
        kinds.add(s.runtimeType);
      }
    }
    return kinds;
  }
}

void main() {
  late _App app;
  late InMemoryFileSource desktop;
  late InMemoryFileSource phone;

  setUp(() async {
    app = _App();
    desktop = await app.add(
      InMemoryFileSource(sourceId: const SourceId('desktop'), pageSize: 5)
        ..withTypicalDownloadFolder(),
      name: 'Desktop',
    );
    phone = await app.add(phoneStorage(), name: 'Phone');
  });

  group('the whole path: button → plan → execution → undo', () {
    test('cleans up both sources and undoes everything', () async {
      final originalDesktop = desktop.snapshot();
      final originalPhone = phone.snapshot();

      await app.workflow.initialize();
      expect(app.workflow.state, const Idle());

      await app.workflow.start();
      expect(app.ready.plans.map((p) => p.source.id), [
        desktop.sourceId,
        phone.sourceId,
      ]);
      expect(app.ready.isEmpty, isFalse);
      expect(app.ready.approvedSummary.fileCount, 18);

      await app.workflow.execute();
      final completed = app.workflow.state as Completed;
      expect(completed.sessions, hasLength(2));
      expect(
        completed.sessions.map((s) => s.status),
        everyElement(SessionStatus.completed),
      );
      expect(desktop.isFile('Документы/notes.txt'), isTrue);
      expect(phone.quarantined, hasLength(3));

      await app.workflow.undo();
      expect(app.workflow.state, isA<Reverted>());
      expect(originalDesktop.diff(desktop.snapshot()), isEmpty);
      expect(originalPhone.diff(phone.snapshot()), isEmpty);

      await pumpEventQueue();
      expect(app.stateKinds, [
        Idle,
        Scanning,
        Analyzing,
        Scanning,
        Analyzing,
        PlanReady,
        Executing,
        Completed,
        Undoing,
        Reverted,
      ]);
    });

    test('reports progress', () async {
      await app.workflow.start();
      await pumpEventQueue();
      final scanning = app.states.whereType<Scanning>().toList();
      expect(scanning.first.filesProcessed, 0);
      expect(scanning.map((s) => s.sourceCount).toSet(), {2});
      expect(
        scanning
            .where((s) => s.sourceId == desktop.sourceId)
            .last
            .filesProcessed,
        desktop.snapshot().files.length - 2,
        reason: 'all but the excluded files',
      );

      await app.workflow.execute();
      await pumpEventQueue();
      final executing = app.states.whereType<Executing>().toList();
      final last = executing.lastWhere((e) => e.sourceId == desktop.sourceId);
      expect(last.progress!.processed, last.progress!.total);
    });

    test('planning again after the cleanup finds nothing', () async {
      await app.workflow.start();
      await app.workflow.execute();
      await app.workflow.start();
      expect(app.ready.isEmpty, isTrue);
    });

    test('start initializes on its own', () async {
      await app.workflow.start();
      expect(app.workflow.state, isA<PlanReady>());
      expect(() => app.workflow.initialize(), throwsStateError);
    });
  });

  group('after a crash', () {
    late FsSnapshot original;

    setUp(() async {
      original = desktop.snapshot();
      await app.workflow.start();
      desktop.crashOn(methods: {FsMethod.move}, nth: 3);
      await expectLater(app.workflow.execute(), throwsA(isA<SimulatedCrash>()));
      desktop.clearFaults();
      app.restart();
      await app.workflow.initialize();
    });

    test('start-up finds and recovers the session', () {
      final interrupted = app.workflow.state as Interrupted;
      expect(interrupted.recovered, hasLength(1));
      expect(interrupted.recovered.single.session.status, SessionStatus.failed);
      expect(interrupted.unavailable, isEmpty);
    });

    test('"finish" plans what is left and does it', () async {
      await app.workflow.start();
      final rest = app.planOf(desktop).plan;
      expect(rest.isEmpty, isFalse);
      await app.workflow.execute();
      expect(app.workflow.state, isA<Completed>());
      await app.workflow.start();
      expect(app.ready.isEmpty, isTrue);
    });

    test('"undo" restores the original tree', () async {
      await app.workflow.undo();
      expect(app.workflow.state, isA<Reverted>());
      expect(original.diff(desktop.snapshot()), isEmpty);
    });

    test('dismissing keeps the session for the history', () async {
      app.workflow.dismiss();
      expect(app.workflow.state, const Idle());
      final id = (await app.repositories.sessions.byStatus(
        SessionStatus.failed,
      )).single.id;
      await app.workflow.undoSession(id);
      expect(original.diff(desktop.snapshot()), isEmpty);
    });
  });

  test('a crashed session whose source is offline waits', () async {
    await app.workflow.start();
    desktop.crashOn(methods: {FsMethod.move});
    await expectLater(app.workflow.execute(), throwsA(isA<SimulatedCrash>()));
    app
      ..offline.add(desktop.sourceId)
      ..restart();
    await app.workflow.initialize();
    final interrupted = app.workflow.state as Interrupted;
    expect(interrupted.recovered, isEmpty);
    expect(interrupted.unavailable, hasLength(1));
    expect(
      await app.repositories.sessions.byStatus(SessionStatus.running),
      hasLength(1),
    );
  });

  test('start-up purges the expired quarantine', () async {
    await app.workflow.start();
    await app.workflow.execute();
    expect(desktop.quarantined, hasLength(1));
    app.clock.advance(const Duration(days: 31));
    app.restart();
    await app.workflow.initialize();
    expect(desktop.quarantined, isEmpty);
    expect(phone.quarantined, hasLength(3), reason: 'system trash');
  });

  group('approvals', () {
    setUp(() => app.workflow.start());

    bool approved(String fromOrTo) => app
        .planOf(desktop)
        .plan
        .operations
        .singleWhere(
          (o) => o.fromPath?.value == fromOrTo || o.toPath?.value == fromOrTo,
        )
        .approved;

    test('a declined group is not executed, nor its folder', () async {
      app.workflow.setGroupApproval(
        desktop.sourceId,
        'move:Документы',
        approved: false,
      );
      expect(approved('Документы'), isFalse);
      expect(approved('Download/notes.txt'), isFalse);

      await app.workflow.execute();
      expect(desktop.isDirectory('Документы'), isFalse);
      expect(desktop.isFile('Download/notes.txt'), isTrue);
      expect(desktop.isFile('Музыка/song.mp3'), isTrue, reason: 'others run');
    });

    test('a shared folder stays approved while another group uses it', () {
      app.workflow.setGroupApproval(
        desktop.sourceId,
        'move:Фото/2023',
        approved: false,
      );
      expect(approved('Фото/2023'), isFalse);
      expect(approved('Фото'), isTrue, reason: 'Фото/2024 still goes there');
    });

    test('single operations, and back again', () async {
      final ops = app.planOf(desktop).plan.operations;
      final notes = ops.indexWhere(
        (o) => o.fromPath?.value == 'Download/notes.txt',
      );
      app.workflow.setOperationApproval(
        desktop.sourceId,
        notes,
        approved: false,
      );
      expect(approved('Download/notes.txt'), isFalse);
      expect(approved('Документы'), isTrue);

      app.workflow.setOperationApproval(
        desktop.sourceId,
        notes,
        approved: true,
      );
      expect(approved('Download/notes.txt'), isTrue);

      app.workflow.setOperationApproval(
        desktop.sourceId,
        notes,
        approved: false,
      );
      await app.workflow.execute();
      expect(desktop.isFile('Download/notes.txt'), isTrue);
      expect(desktop.isFile('Документы/table.xlsx'), isTrue);
    });

    test('folders cannot be toggled by hand', () {
      final mkdir = app
          .planOf(desktop)
          .plan
          .operations
          .indexWhere((o) => o.type == OperationType.mkdir);
      expect(
        () => app.workflow.setOperationApproval(
          desktop.sourceId,
          mkdir,
          approved: false,
        ),
        throwsArgumentError,
      );
    });

    test('unknown groups, indexes and sources are refused', () {
      expect(
        () => app.workflow.setGroupApproval(
          desktop.sourceId,
          'nope',
          approved: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => app.workflow.setOperationApproval(
          desktop.sourceId,
          999,
          approved: false,
        ),
        throwsRangeError,
      );
      expect(
        () => app.workflow.setGroupApproval(
          const SourceId('nope'),
          'duplicates',
          approved: false,
        ),
        throwsArgumentError,
      );
    });

    test('declining the whole plan changes nothing', () {
      final before = desktop.snapshot();
      app.workflow.dismiss();
      expect(app.workflow.state, const Idle());
      expect(desktop.snapshot(), before);
    });
  });

  group('cancellation', () {
    test('while scanning: back to idle, the scan resumes next time', () async {
      var cancelled = false;
      app.workflow.states.listen((s) {
        if (!cancelled && s is Scanning && s.filesProcessed >= 10) {
          cancelled = true;
          app.workflow.cancel();
        }
      });
      await app.workflow.start();
      expect(app.workflow.state, const Idle());
      expect(
        await app.repositories.checkpoints.bySource(desktop.sourceId),
        isNotNull,
      );

      await app.workflow.start();
      expect(app.planOf(desktop).scan.resumed, isTrue);
    });

    test('while hashing: stops inside the file, back to idle', () async {
      const block = InMemoryFileSource.hashBlockSize;
      desktop.addFile('Download/video.mp4', bytes: List.filled(block * 5, 3));
      desktop.addFile(
        'Download/video (1).mp4',
        bytes: List.filled(block * 5, 3),
      );
      final afterCancel = <String>[];
      var cancelled = false;
      desktop.onHashBlock = (path, n) {
        if (cancelled) {
          afterCancel.add('$path#$n');
        } else if (path.value == 'Download/video.mp4') {
          cancelled = true;
          app.workflow.cancel();
        }
      };
      await app.workflow.start();
      expect(app.workflow.state, const Idle());
      expect(afterCancel, isEmpty, reason: 'no block is read after cancel');

      desktop.onHashBlock = null;
      await app.workflow.start();
      expect(app.workflow.state, isA<PlanReady>());
      expect(
        app.planOf(desktop).plan.operations.map((o) => o.fromPath?.value),
        contains('Download/video (1).mp4'),
      );
    });

    test('while executing: cancelled, then undone completely', () async {
      final original = desktop.snapshot();
      await app.workflow.start();
      app.workflow.states.listen((s) {
        if (s is Executing && s.progress?.processed == 3) {
          app.workflow.cancel();
        }
      });
      await app.workflow.execute();
      final cancelled = app.workflow.state as Cancelled;
      expect(cancelled.sessions.single.status, SessionStatus.cancelled);
      expect(phone.quarantined, isEmpty, reason: 'phone never started');

      await app.workflow.undo();
      expect(app.workflow.state, isA<Reverted>());
      expect(original.diff(desktop.snapshot()), isEmpty);
    });

    test('while undoing: partially reverted, then finished', () async {
      final original = desktop.snapshot();
      await app.workflow.start();
      await app.workflow.execute();
      var cancelled = false;
      app.workflow.states.listen((s) {
        if (!cancelled && s is Undoing && s.operationsProcessed == 2) {
          cancelled = true;
          app.workflow.cancel();
        }
      });
      await app.workflow.undo();
      expect(app.workflow.state, isA<PartiallyReverted>());

      await app.workflow.undo();
      expect(app.workflow.state, isA<Reverted>());
      expect(original.diff(desktop.snapshot()), isEmpty);
    });

    test(
      'before the first operation: an empty session, undone at once',
      () async {
        await app.workflow.start();
        app.workflow.states.listen((s) {
          if (s is Executing && s.progress == null) {
            app.workflow.cancel();
          }
        });
        final before = desktop.snapshot();
        await app.workflow.execute();
        final cancelled = app.workflow.state as Cancelled;
        expect(cancelled.sessions.single.stats.total, 0);
        expect(desktop.snapshot(), before);

        await app.workflow.undo();
        expect(app.workflow.state, isA<Reverted>());
      },
    );

    test('does nothing when nothing runs', () {
      app.workflow.cancel();
      expect(app.workflow.state, const Idle());
    });
  });

  group('sources', () {
    test('a source that cannot be opened is skipped and reported', () async {
      app.offline.add(phone.sourceId);
      await app.workflow.start();
      expect(app.ready.plans.map((p) => p.source.id), [desktop.sourceId]);
      expect(app.ready.unavailable, [phone.sourceId]);
    });

    test('a disabled source is not touched', () async {
      final off = await app.add(
        InMemoryFileSource(sourceId: const SourceId('off'))
          ..withTypicalDownloadFolder(),
        enabled: false,
      );
      await app.workflow.start();
      expect(off.calls, isEmpty);
      expect(app.ready.plans, hasLength(2));
    });

    test('the adapter folders are never scanned or cleaned', () async {
      // Inside a messenger media folder, which is cleaned with all its
      // subfolders: only the adapter's own folder must be left out.
      final own = await app.add(
        InMemoryFileSource(
            sourceId: const SourceId('own'),
            appFolders: {LogicalPath('Telegram/Organizer')},
          )
          ..addFile('Telegram/Organizer/s1/a.pdf')
          ..addFile('Telegram/Telegram Documents/b.pdf'),
      );
      await app.workflow.start();
      final moved = [
        for (final op in app.planOf(own).plan.operations)
          if (op.fromPath case final from?) from.value,
      ];
      expect(moved, ['Telegram/Telegram Documents/b.pdf']);
      final indexed = await app.repositories.index.bySource(own.sourceId);
      expect(
        indexed.map((e) => e.path.value),
        isNot(contains('Telegram/Organizer/s1/a.pdf')),
      );
    });

    test(
      'a scan failure ends in failed, from where one can start over',
      () async {
        desktop.failOn(FileErrorKind.ioError, methods: {FsMethod.list});
        await app.workflow.start();
        final failed = app.workflow.state as Failed;
        expect(failed.reason, contains('Desktop'));

        app.workflow.dismiss();
        await app.workflow.start();
        expect(app.workflow.state, isA<PlanReady>());
      },
    );
  });

  test('user zones and rules are applied', () async {
    await app.repositories.rules.saveZoneOverride(
      ZoneOverride(
        sourceId: desktop.sourceId,
        folder: LogicalPath('Download'),
        zone: Zone.organized,
      ),
    );
    await app.repositories.rules.saveClassificationRule(
      ClassificationRule(
        id: 'photos-are-other',
        category: Category.other,
        extensions: const {'jpg'},
      ),
    );
    await app.workflow.start();
    expect(app.planOf(desktop).plan.isEmpty, isTrue);
    // The phone has only duplicates to quarantine; no jpg is moved anyway.
    expect(app.planOf(phone).plan.isEmpty, isFalse);
  });

  test('undo from the history', () async {
    final original = desktop.snapshot();
    await app.workflow.start();
    await app.workflow.execute();
    final session = (app.workflow.state as Completed).sessions.first;
    app.workflow.dismiss();

    await app.workflow.undoSession(session.id);
    expect(app.workflow.state, isA<Reverted>());
    expect(original.diff(desktop.snapshot()), isEmpty);
  });

  test('an undo with conflicts ends partially reverted', () async {
    await app.workflow.start();
    await app.workflow.execute();
    desktop.removeExternally('Документы/notes.txt');
    await app.workflow.undo();
    expect(app.workflow.state, isA<PartiallyReverted>());
  });

  group('commands that do not fit the state are refused', () {
    test('in idle', () {
      expect(() => app.workflow.execute(), throwsStateError);
      expect(() => app.workflow.undo(), throwsStateError);
      expect(app.workflow.dismiss, throwsStateError);
      expect(
        () => app.workflow.setGroupApproval(
          desktop.sourceId,
          'duplicates',
          approved: false,
        ),
        throwsStateError,
      );
    });

    test('while another command runs', () async {
      final first = app.workflow.start();
      expect(() => app.workflow.start(), throwsStateError);
      expect(app.workflow.dismiss, throwsStateError);
      await first;
    });

    test('in plan ready', () async {
      await app.workflow.start();
      expect(() => app.workflow.undo(), throwsStateError);
      expect(() => app.workflow.initialize(), throwsStateError);
    });

    test('after completion', () async {
      await app.workflow.start();
      await app.workflow.execute();
      expect(() => app.workflow.execute(), throwsStateError);
    });
  });

  test('a new listener first gets the current state', () async {
    await app.workflow.start();
    expect(await app.workflow.states.first, isA<PlanReady>());
  });
}
