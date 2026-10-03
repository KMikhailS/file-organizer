import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/recovery/recovery.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/pipeline_harness.dart';
import '../../support/scenarios.dart';

void main() {
  late InMemoryFileSource fs;
  late PipelineHarness harness;
  late FsSnapshot original;
  late SessionId sessionId;

  /// Plans a cleanup of [source] and runs it until the first call of
  /// [method] crashes at [point].
  Future<void> crashOn(
    InMemoryFileSource source,
    FsMethod method,
    CrashPoint point,
  ) async {
    fs = source;
    harness = PipelineHarness(fs);
    final plan = await harness.readyPlan();
    original = fs.snapshot();
    fs.crashOn(methods: {method}, point: point);
    final run = harness.executor.start(fs, plan);
    sessionId = run.sessionId;
    await expectLater(run.result, throwsA(isA<SimulatedCrash>()));
    fs.clearFaults();
  }

  Future<RecoveryResult> recover() =>
      harness.recovery.recover(sessionId, source: fs);

  Future<void> expectUndoRestoresEverything() async {
    final undo = await harness.undo(sessionId);
    expect(original.diff(fs.snapshot()), isEmpty);
    expect(undo.session.status, SessionStatus.reverted);
  }

  /// (method, point) → expected status of the interrupted operation.
  final cases = {
    (FsMethod.mkdir, CrashPoint.beforeEffect): OperationStatus.skipped,
    (FsMethod.mkdir, CrashPoint.afterEffect): OperationStatus.done,
    (FsMethod.move, CrashPoint.beforeEffect): OperationStatus.skipped,
    (FsMethod.move, CrashPoint.afterEffect): OperationStatus.done,
    (FsMethod.quarantine, CrashPoint.beforeEffect): OperationStatus.skipped,
    (FsMethod.quarantine, CrashPoint.afterEffect): OperationStatus.done,
  };

  for (final MapEntry(key: (method, point), value: expected) in cases.entries) {
    group('a crash ${point.name} ${method.name}', () {
      setUp(
        () => crashOn(
          InMemoryFileSource()..withTypicalDownloadFolder(),
          method,
          point,
        ),
      );

      test('is found at start-up', () async {
        expect(
          (await harness.recovery.interruptedSessions()).map((s) => s.id),
          [sessionId],
        );
        expect(await harness.recovery.sourceOf(sessionId), fs.sourceId);
      });

      test('leaves the operation ${expected.name}', () async {
        final result = await recover();
        final op = result.recovered.single;
        expect(op.type.name, method.name);
        expect(op.status, expected);
        expect(op.executedAt, isNotNull);
        if (expected == OperationStatus.skipped) {
          expect(op.error, startsWith('interrupted: '));
        }
        if (op.type == OperationType.quarantine &&
            expected == OperationStatus.done) {
          expect(op.quarantineRef!.value, fs.quarantined.keys.single);
        }
      });

      test('closes the session as failed with its stats', () async {
        final result = await recover();
        expect(result.session.status, SessionStatus.failed);
        expect(result.session.finishedAt, isNotNull);
        expect(result.session.stats.pending, 0);
        expect(await harness.recovery.interruptedSessions(), isEmpty);
        expect(await harness.sessions.byId(sessionId), result.session);
      });

      test('then the undo restores the original tree', () async {
        await recover();
        await expectUndoRestoresEverything();
      });

      test('then planning again finishes the job', () async {
        await recover();
        final rest = await harness.readyPlan();
        expect(rest.isEmpty, isFalse);
        await harness.execute(rest);
        expect((await harness.readyPlan()).isEmpty, isTrue);
      });
    });
  }

  group('iOS album', () {
    for (final point in CrashPoint.values) {
      test('a crash ${point.name} addToAlbum: done, undo is safe', () async {
        await crashOn(
          InMemoryFileSource(capabilities: iosPhotosCapabilities)
            ..addFile(
              'IMG_1.HEIC',
              text: 'same',
              modifiedAt: DateTime.utc(2020),
            )
            ..addFile(
              'IMG_2.HEIC',
              text: 'same',
              modifiedAt: DateTime.utc(2021),
            ),
          FsMethod.addToAlbum,
          point,
        );
        final result = await recover();
        expect(result.recovered.single.status, OperationStatus.done);
        await expectUndoRestoresEverything();
      });
    }
  });

  group('needs attention', () {
    test('a moved file that is nowhere to be found', () async {
      await crashOn(
        InMemoryFileSource()..withTypicalDownloadFolder(),
        FsMethod.move,
        CrashPoint.afterEffect,
      );
      final pending = (await harness.operations(sessionId)).last;
      fs.removeExternally(pending.toPath!.value);
      final op = (await recover()).recovered.single;
      expect(op.status, OperationStatus.failed);
      expect(
        op.error,
        '${Recovery.needsAttention}: '
        'the file is neither at its old nor its new place',
      );
    });

    test('a quarantined file whose quarantine object is gone', () async {
      await crashOn(
        InMemoryFileSource()..withTypicalDownloadFolder(),
        FsMethod.quarantine,
        CrashPoint.afterEffect,
      );
      await fs.purgeQuarantined(QuarantineRef(fs.quarantined.keys.single));
      final op = (await recover()).recovered.single;
      expect(op.status, OperationStatus.failed);
      expect(op.error, startsWith(Recovery.needsAttention));
    });

    test('a file that cannot be checked', () async {
      await crashOn(
        InMemoryFileSource()..withTypicalDownloadFolder(),
        FsMethod.move,
        CrashPoint.beforeEffect,
      );
      fs.denyAccess('Download');
      final op = (await recover()).recovered.single;
      expect(op.status, OperationStatus.failed);
      expect(
        op.error,
        '${Recovery.needsAttention}: cannot check: permissionDenied',
      );
    });
  });

  test('a move is judged by its source first', () async {
    // The move did not happen, but a file with the same size and time
    // appeared at the target: it is not ours.
    await crashOn(
      InMemoryFileSource()..withTypicalDownloadFolder(),
      FsMethod.move,
      CrashPoint.beforeEffect,
    );
    final pending = (await harness.operations(sessionId)).last;
    fs.addFile(
      pending.toPath!.value,
      bytes: fs.readBytes(pending.fromPath!.value),
      modifiedAt: pending.fingerprint!.modifiedAt,
    );
    expect((await recover()).recovered.single.status, OperationStatus.skipped);
  });

  test('a session with nothing pending is just closed', () async {
    fs = InMemoryFileSource()..withTypicalDownloadFolder();
    harness = PipelineHarness(fs);
    final session = CleanupSession(
      id: const SessionId('s'),
      startedAt: DateTime.utc(2024),
      status: SessionStatus.planned,
      stats: SessionStats.empty,
    );
    await harness.sessions.save(session);
    await harness.sessions.save(session.transitionTo(SessionStatus.running));
    sessionId = session.id;

    expect(await harness.recovery.sourceOf(sessionId), isNull);
    final result = await harness.recovery.recover(sessionId);
    expect(result.recovered, isEmpty);
    expect(result.session.status, SessionStatus.failed);
  });

  group('refuses', () {
    setUp(
      () => crashOn(
        InMemoryFileSource()..withTypicalDownloadFolder(),
        FsMethod.move,
        CrashPoint.afterEffect,
      ),
    );

    test('a session that is not running', () async {
      await recover();
      expect(recover(), throwsStateError);
      expect(
        harness.recovery.recover(const SessionId('nope')),
        throwsStateError,
      );
    });

    test('pending operations without their source', () {
      expect(harness.recovery.recover(sessionId), throwsStateError);
    });

    test('another source', () {
      expect(
        harness.recovery.recover(
          sessionId,
          source: InMemoryFileSource(sourceId: const SourceId('other')),
        ),
        throwsArgumentError,
      );
    });
  });
}
