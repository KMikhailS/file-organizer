import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/core/undo/undo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/pipeline_harness.dart';
import '../../support/scenarios.dart';

void main() {
  late InMemoryFileSource fs;
  late PipelineHarness harness;
  late FsSnapshot original;
  late CleanupSession session;

  /// Plans and executes a cleanup of [source].
  Future<void> cleanUp(InMemoryFileSource source) async {
    fs = source;
    harness = PipelineHarness(fs);
    final plan = await harness.readyPlan();
    original = fs.snapshot();
    session = await harness.execute(plan);
  }

  Future<UndoResult> undo([UndoScope scope = const WholeSession()]) =>
      harness.undo(session.id, scope: scope);

  Future<Operation> op(String fromOrTo) async =>
      (await harness.operations(session.id)).singleWhere(
        (o) => o.fromPath?.value == fromOrTo || o.toPath?.value == fromOrTo,
      );

  group('full undo', () {
    setUp(() => cleanUp(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('restores the original file tree', () async {
      await undo();
      expect(original.diff(fs.snapshot()), isEmpty);
      expect(fs.quarantined, isEmpty);
    });

    test('reverts every operation, last first', () async {
      final result = await undo();
      final journal = await harness.operations(session.id);
      expect(
        result.entries.map((e) => e.operation.seq),
        journal.map((o) => o.seq).toList().reversed,
      );
      expect(
        journal.map((o) => o.status),
        everyElement(OperationStatus.reverted),
      );
      expect(journal.map((o) => o.revertedAt), everyElement(isNotNull));
      expect(result.entries.map((e) => e.restoredAs), everyElement(isNull));
    });

    test('marks the session reverted with its stats', () async {
      final result = await undo();
      expect(result.session.status, SessionStatus.reverted);
      expect(result.session.finishedAt, session.finishedAt);
      expect(result.session.stats.reverted, session.stats.done);
      expect(result.session.stats.removedBytes, 0);
      expect(await harness.sessions.byId(session.id), result.session);
    });

    test('a second undo does nothing', () async {
      await undo();
      final before = fs.snapshot();
      final again = await undo();
      expect(again.entries, isEmpty);
      expect(again.session.status, SessionStatus.reverted);
      expect(fs.snapshot(), before);
    });
  });

  group('partial undo', () {
    setUp(() => cleanUp(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('one group', () async {
      final result = await undo(const OneGroup('duplicates'));
      expect(result.entries, hasLength(1));
      expect(fs.isFile('Download/invoice_2024 (1).pdf'), isTrue);
      expect(fs.isFile('Документы/notes.txt'), isTrue, reason: 'not undone');
      expect(result.session.status, SessionStatus.partiallyReverted);
    });

    test('one operation', () async {
      final move = await op('Download/notes.txt');
      final result = await undo(OneOperation(move.id));
      expect(result.entries.single.operation.status, OperationStatus.reverted);
      expect(fs.isFile('Download/notes.txt'), isTrue);
      expect(fs.isFile('Документы/table.xlsx'), isTrue);
    });

    test('a shared folder stays until everything in it is undone', () async {
      // "Фото" was created for the 2023 photos; the 2024 ones still use it.
      final result = await undo(const OneGroup('move:Фото/2023'));
      final folder = result.entries.singleWhere(
        (e) => e.operation.toPath?.value == 'Фото',
      );
      expect(folder.operation.status, OperationStatus.revertSkipped);
      expect(folder.operation.error, 'folder is not empty');
      expect(fs.isDirectory('Фото/2023'), isFalse);
      expect(fs.isDirectory('Фото'), isTrue);

      // A full undo retries it and finishes the job.
      final full = await undo();
      expect(full.session.status, SessionStatus.reverted);
      expect(original.diff(fs.snapshot()), isEmpty);
    });

    test('groups one by one add up to a full undo', () async {
      final plan = (await harness.operations(session.id))
          .map((o) => o.groupKey)
          .toSet()
          .toList();
      for (final group in plan.reversed) {
        await undo(OneGroup(group));
      }
      final last = await undo();
      expect(last.session.status, SessionStatus.reverted);
      expect(original.diff(fs.snapshot()), isEmpty);
    });
  });

  group('conflicts', () {
    setUp(() => cleanUp(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('a file no longer where the cleanup put it is skipped', () async {
      fs.removeExternally('Документы/notes.txt');
      final result = await undo();
      final notes = await op('Download/notes.txt');
      expect(notes.status, OperationStatus.revertSkipped);
      expect(notes.error, 'the file is not where the cleanup put it');
      expect(result.session.status, SessionStatus.partiallyReverted);
      expect(fs.isFile('Download/table.xlsx'), isTrue, reason: 'rest goes on');
    });

    test('a file changed since the cleanup is skipped', () async {
      fs.writeFile(
        'Документы/notes.txt',
        text: 'edited',
        modifiedAt: DateTime.utc(2030),
      );
      await undo();
      final notes = await op('Download/notes.txt');
      expect(notes.status, OperationStatus.revertSkipped);
      expect(notes.error, 'the file changed since the cleanup');
      expect(fs.readText('Документы/notes.txt'), 'edited');
      final folder = await op('Документы');
      expect(folder.status, OperationStatus.revertSkipped);
      expect(folder.error, 'folder is not empty');
    });

    test(
      'a taken original place: restored next to it, nothing overwritten',
      () async {
        fs
          ..addFile('Download/notes.txt', text: 'a new file')
          ..addFile('Download/notes (восстановлено).txt', text: 'and another');
        final result = await undo();

        final entry = result.entries.singleWhere(
          (e) => e.operation.fromPath?.value == 'Download/notes.txt',
        );
        expect(entry.operation.status, OperationStatus.reverted);
        expect(
          entry.restoredAs,
          LogicalPath('Download/notes (восстановлено 2).txt'),
        );
        expect(fs.readText('Download/notes.txt'), 'a new file');
        expect(
          fs.readText('Download/notes (восстановлено).txt'),
          'and another',
        );
        expect(
          fs.readText('Download/notes (восстановлено 2).txt'),
          'Download/notes.txt',
        );
      },
    );

    test('a taken place for a quarantined file', () async {
      fs.addFile('Download/invoice_2024 (1).pdf', text: 'new');
      final result = await undo(const OneGroup('duplicates'));
      expect(
        result.entries.single.restoredAs,
        LogicalPath('Download/invoice_2024 (1) (восстановлено).pdf'),
      );
      expect(fs.readText('Download/invoice_2024 (1).pdf'), 'new');
    });

    test('a missing original folder is created again', () async {
      await cleanUp(InMemoryFileSource()..addFile('Download/a.pdf'));
      fs.removeExternally('Download');
      final result = await undo();
      expect(result.session.status, SessionStatus.reverted);
      expect(fs.isFile('Download/a.pdf'), isTrue);
    });

    test('a purged quarantine is reported', () async {
      final quarantine = await op('Download/invoice_2024 (1).pdf');
      await fs.purgeQuarantined(quarantine.quarantineRef!);
      final result = await undo();
      final entry = result.entries.singleWhere(
        (e) => e.operation.id == quarantine.id,
      );
      expect(entry.operation.status, OperationStatus.revertSkipped);
      expect(entry.operation.error, 'the quarantine was purged');
      expect(result.session.status, SessionStatus.partiallyReverted);
    });

    test('a folder the user put files into stays', () async {
      fs.addFile('Музыка/mine.mp3');
      await undo();
      expect((await op('Музыка')).error, 'folder is not empty');
      expect(fs.isFile('Музыка/mine.mp3'), isTrue);
      expect(fs.isFile('Download/song.mp3'), isTrue);
    });

    test('a folder already removed counts as undone', () async {
      // Undo the move into Музыка, then remove the empty folder by hand.
      await undo(OneOperation((await op('Download/song.mp3')).id));
      fs.removeExternally('Музыка');
      final result = await undo(OneOperation((await op('Музыка')).id));
      expect(result.entries.single.operation.status, OperationStatus.reverted);
    });

    test('a skipped undo can be retried once the conflict is gone', () async {
      final kept = fs.readBytes('Документы/notes.txt');
      final time = fs.snapshot().files['Документы/notes.txt']!.modifiedAt;
      fs.removeExternally('Документы/notes.txt');
      expect((await undo()).session.status, SessionStatus.partiallyReverted);

      // The user puts the file back, which recreates the folder the first
      // undo had already removed.
      fs.addFile('Документы/notes.txt', bytes: kept, modifiedAt: time);
      final retry = await undo();
      expect(retry.session.status, SessionStatus.reverted);
      expect(
        retry.entries.single.operation.fromPath,
        LogicalPath('Download/notes.txt'),
      );
      // That folder is the user's now: the undo does not remove it again.
      expect(original.diff(fs.snapshot()), ['+ dir Документы']);
    });
  });

  test('a source without a restorable quarantine', () async {
    await cleanUp(
      InMemoryFileSource(
          capabilities: const SourceCapabilities(
            canMove: true,
            canMkdir: true,
            canQuarantine: true,
          ),
        )
        ..addFile(
          'Download/a.pdf',
          text: 'same',
          modifiedAt: DateTime.utc(2020),
        )
        ..addFile(
          'Download/b.pdf',
          text: 'same',
          modifiedAt: DateTime.utc(2021),
        ),
    );
    final result = await undo();
    final quarantine = await op('Download/b.pdf');
    expect(quarantine.status, OperationStatus.revertSkipped);
    expect(quarantine.error, 'this source cannot restore from its quarantine');
    expect(fs.isFile('Download/a.pdf'), isTrue, reason: 'the move is undone');
    expect(result.session.status, SessionStatus.partiallyReverted);
  });

  test('iOS Photos: photos leave the album', () async {
    await cleanUp(
      InMemoryFileSource(capabilities: iosPhotosCapabilities)
        ..addFile('IMG_1.HEIC', text: 'same', modifiedAt: DateTime.utc(2020))
        ..addFile('IMG_2.HEIC', text: 'same', modifiedAt: DateTime.utc(2021)),
    );
    expect(fs.album, isNotEmpty);
    final result = await undo();
    expect(fs.album, isEmpty);
    expect(result.session.status, SessionStatus.reverted);
    expect(original.diff(fs.snapshot()), isEmpty);
  });

  group('sessions that stopped early', () {
    test('a cancelled cleanup is undone completely', () async {
      fs = InMemoryFileSource()..withTypicalDownloadFolder();
      harness = PipelineHarness(fs);
      final plan = await harness.readyPlan();
      original = fs.snapshot();
      final run = harness.executor.start(fs, plan);
      run.progress.listen((p) {
        if (p.processed == 5) {
          run.cancel();
        }
      });
      session = await run.result;
      expect(session.status, SessionStatus.cancelled);

      final result = await undo();
      expect(result.session.status, SessionStatus.reverted);
      expect(original.diff(fs.snapshot()), isEmpty);
    });

    test('failed and skipped operations are left as they are', () async {
      fs = InMemoryFileSource()..withTypicalDownloadFolder();
      harness = PipelineHarness(fs);
      final plan = await harness.readyPlan();
      fs
        ..failOn(FileErrorKind.ioError, methods: {FsMethod.move}, nth: 3)
        ..writeFile('Download/song.mp3', modifiedAt: DateTime.utc(2031));
      original = fs.snapshot();
      session = await harness.execute(plan);
      fs.clearFaults();

      final result = await undo();
      expect(result.session.status, SessionStatus.reverted);
      expect(original.diff(fs.snapshot()), isEmpty);
      final statuses = (await harness.operations(session.id))
          .map((o) => o.status)
          .toSet();
      expect(statuses, {
        OperationStatus.reverted,
        OperationStatus.failed,
        OperationStatus.skipped,
      });
    });

    test('a session still running (not recovered) cannot be undone', () async {
      fs = InMemoryFileSource()..withTypicalDownloadFolder();
      harness = PipelineHarness(fs);
      final plan = await harness.readyPlan();
      fs.crashOn(methods: {FsMethod.move});
      final run = harness.executor.start(fs, plan);
      await expectLater(run.result, throwsA(isA<SimulatedCrash>()));
      expect(harness.undo(run.sessionId), throwsStateError);
    });
  });

  test('a session without operations needs no source', () async {
    fs = InMemoryFileSource()..withTypicalDownloadFolder();
    harness = PipelineHarness(fs);
    final plan = await harness.readyPlan();
    final run = harness.executor.start(fs, plan)..cancel();
    session = await run.result;
    final result = await harness.undoService.start(null, session.id).result;
    expect(result.entries, isEmpty);
    expect(result.session.status, SessionStatus.reverted);
  });

  group('cancellation', () {
    setUp(() => cleanUp(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('stops after the current operation', () async {
      final run = harness.undoService.start(fs, session.id);
      var seen = 0;
      run.progress.listen((_) {
        if (++seen == 2) {
          run.cancel();
        }
      });
      final result = await run.result;
      expect(result.entries, hasLength(2));
      expect(result.session.status, SessionStatus.partiallyReverted);

      final rest = await undo();
      expect(rest.session.status, SessionStatus.reverted);
      expect(original.diff(fs.snapshot()), isEmpty);
    });
  });

  group('refuses', () {
    setUp(() => cleanUp(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('an unknown session', () {
      expect(harness.undo(const SessionId('nope')), throwsStateError);
    });

    test('an operation of another session', () {
      expect(undo(const OneOperation(OperationId('nope'))), throwsStateError);
    });

    test('another source', () {
      final other = InMemoryFileSource(sourceId: const SourceId('other'));
      expect(
        harness.undoService.start(other, session.id).result,
        throwsArgumentError,
      );
    });

    test('a missing source when there is something to undo', () {
      expect(
        harness.undoService.start(null, session.id).result,
        throwsStateError,
      );
    });

    test('a bad restored label', () {
      expect(
        () => UndoService(
          journal: harness.journal,
          sessions: harness.sessions,
          clock: harness.clock,
          restoredLabel: 'a/b',
        ),
        throwsArgumentError,
      );
    });
  });
}
