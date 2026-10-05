import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/core/quarantine/quarantine_purger.dart';
import 'package:file_organizer/core/undo/undo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/pipeline_harness.dart';
import '../../support/scenarios.dart';

void main() {
  late InMemoryFileSource fs;
  late PipelineHarness harness;
  late CleanupSession session;

  Future<void> cleanUp(InMemoryFileSource source) async {
    fs = source;
    harness = PipelineHarness(fs);
    session = await harness.execute(await harness.readyPlan());
  }

  Future<PurgeResult> purgeAfter(
    Duration age, {
    Map<SourceId, FileSource>? sources,
  }) {
    harness.clock.advance(age);
    return harness.purger.purgeExpired(sources ?? {fs.sourceId: fs});
  }

  Future<Operation> quarantineOp() async =>
      (await harness.operations(session.id))
          .singleWhere((o) => o.type == OperationType.quarantine);

  group('by age', () {
    setUp(() => cleanUp(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('purges what is older than 30 days by default', () async {
      final result = await purgeAfter(const Duration(days: 31));
      expect(result.purged, hasLength(1));
      expect(fs.quarantined, isEmpty);
      final op = await quarantineOp();
      expect(op.status, OperationStatus.revertSkipped);
      expect(op.error, const QuarantinePurged());
      expect(op.quarantineRef, isNotNull, reason: 'kept for the record');
    });

    test('keeps what is younger', () async {
      final result = await purgeAfter(const Duration(days: 29));
      expect(result.purged, isEmpty);
      expect(result.kept, isEmpty);
      expect(fs.quarantined, hasLength(1));
      expect((await quarantineOp()).status, OperationStatus.done);
    });

    test('follows the retention setting', () async {
      await harness.settings.save(
        Settings(quarantineRetention: const Duration(days: 7)),
      );
      expect((await purgeAfter(const Duration(days: 8))).purged, hasLength(1));
    });

    test('updates the session stats', () async {
      await purgeAfter(const Duration(days: 31));
      final stored = (await harness.sessions.byId(session.id))!;
      expect(stored.status, session.status);
      expect(stored.stats.revertSkipped, 1);
      expect(stored.stats.done, session.stats.done - 1);
    });

    test('purges each file once', () async {
      await purgeAfter(const Duration(days: 31));
      final again = await purgeAfter(const Duration(days: 1));
      expect(again.purged, isEmpty);
      expect(
        fs.calls.where((c) => c.method == FsMethod.purgeQuarantined),
        hasLength(1),
      );
    });

    test('marks a file already gone from the quarantine', () async {
      await fs.purgeQuarantined((await quarantineOp()).quarantineRef!);
      final result = await purgeAfter(const Duration(days: 31));
      expect(result.purged, hasLength(1));
    });

    test('keeps a file it fails to purge', () async {
      fs.failOn(FileErrorKind.locked, methods: {FsMethod.purgeQuarantined});
      final result = await purgeAfter(const Duration(days: 31));
      expect(result.kept.single.reason, 'purge failed: locked');
      expect((await quarantineOp()).status, OperationStatus.done);
      expect(fs.quarantined, hasLength(1));
    });
  });

  test('undo after the purge: impossible for the purged file only', () async {
    await cleanUp(InMemoryFileSource()..withTypicalDownloadFolder());
    await purgeAfter(const Duration(days: 31));
    final undo = await harness.undo(session.id);
    final op = await quarantineOp();
    expect(op.status, OperationStatus.revertSkipped);
    expect(op.error, const QuarantinePurged());
    expect(undo.session.status, SessionStatus.partiallyReverted);
    expect(
      fs.isFile('Download/notes.txt'),
      isTrue,
      reason: 'the rest is undone',
    );
  });

  group('leaves alone', () {
    test('a system trash that empties itself', () async {
      await cleanUp(phoneStorage());
      final result = await purgeAfter(const Duration(days: 31));
      expect(result.purged, isEmpty);
      expect(result.kept.map((k) => k.reason).toSet(), {
        'the system empties this quarantine',
      });
      expect(fs.quarantined, hasLength(3));
    });

    test('a source that is not available', () async {
      await cleanUp(InMemoryFileSource()..withTypicalDownloadFolder());
      final result = await purgeAfter(const Duration(days: 31), sources: {});
      expect(result.kept.single.reason, 'the source is not available');
      expect(fs.quarantined, hasLength(1));
    });

    test('a session not recovered yet', () async {
      fs = InMemoryFileSource()..withTypicalDownloadFolder();
      harness = PipelineHarness(fs);
      final plan = await harness.readyPlan();
      fs.crashOn(methods: {FsMethod.move});
      final run = harness.executor.start(fs, plan);
      await expectLater(run.result, throwsA(isA<SimulatedCrash>()));
      fs.clearFaults();

      final result = await purgeAfter(const Duration(days: 31));
      expect(result.kept.single.reason, 'the session has not finished');
      expect(fs.quarantined, hasLength(1));
    });

    test('a file whose undo was already tried', () async {
      await cleanUp(InMemoryFileSource()..withTypicalDownloadFolder());
      fs.failOn(FileErrorKind.ioError, methods: {FsMethod.restore});
      await harness.undo(session.id, scope: const OneGroup('duplicates'));
      expect((await quarantineOp()).status, OperationStatus.revertSkipped);

      final result = await purgeAfter(const Duration(days: 31));
      expect(result.purged, isEmpty);
      expect(fs.quarantined, hasLength(1));
    });
  });
}
