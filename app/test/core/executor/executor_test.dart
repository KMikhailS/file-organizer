import 'dart:math' as math;

import 'package:file_organizer/core/executor/execution.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/pipeline_harness.dart';
import '../../support/repositories/in_memory_repositories.dart';
import '../../support/scenarios.dart';
import '../../support/sequential_id_generator.dart';

void main() {
  late InMemoryFileSource fs;
  late InMemoryOperationJournal journal;
  late InMemorySessionRepository sessions;
  late Executor executor;
  late Plan plan;

  Executor newExecutor({
    OperationJournal? using,
    int batchSize = Executor.defaultBatchSize,
  }) => Executor(
    journal: using ?? journal,
    sessions: sessions,
    clock: FakeClock(autoAdvance: const Duration(seconds: 1)),
    ids: SequentialIdGenerator('x'),
    batchSize: batchSize,
  );

  Future<void> setUpWith(InMemoryFileSource source) async {
    fs = source;
    plan = await PipelineHarness(fs).readyPlan();
    journal = InMemoryOperationJournal();
    sessions = InMemorySessionRepository();
    executor = newExecutor();
  }

  Future<CleanupSession> execute([Plan? p]) =>
      executor.start(fs, p ?? plan).result;

  Future<Operation> journaled(String fromOrTo) async {
    final session = (await sessions.all()).single;
    return (await journal.bySession(session.id)).singleWhere(
      (o) => o.fromPath?.value == fromOrTo || o.toPath?.value == fromOrTo,
    );
  }

  group('successful execution', () {
    setUp(() => setUpWith(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('does what the plan says', () async {
      final expected = InMemoryFileSource()..withTypicalDownloadFolder();
      await applyPlan(expected, plan);

      await execute();

      expect(fs.snapshot().tree, expected.snapshot().tree);
      expect(fs.quarantined.values, [
        LogicalPath('Download/invoice_2024 (1).pdf'),
      ]);
    });

    test('journals every operation as done, in plan order', () async {
      final session = await execute();
      final ops = await journal.bySession(session.id);
      expect(ops.map((o) => o.seq), List.generate(ops.length, (i) => i));
      expect(
        ops.map((o) => (o.type, o.fromPath, o.toPath)),
        plan.operations.map((o) => (o.type, o.fromPath, o.toPath)),
      );
      expect(ops.map((o) => o.status), everyElement(OperationStatus.done));
      expect(ops.map((o) => o.executedAt), everyElement(isNotNull));
      expect(ops.first.type, OperationType.quarantine);
      expect(ops.first.quarantineRef!.value, fs.quarantined.keys.single);
    });

    test('completes the session with its stats', () async {
      final session = await execute();
      expect(session.status, SessionStatus.completed);
      expect(session.finishedAt, isNotNull);
      expect(session.stats.total, plan.operations.length);
      expect(session.stats.done, plan.operations.length);
      expect(session.stats.removedBytes, plan.summary.reclaimableBytes);
      expect(await sessions.byId(session.id), session);
    });

    test('reports progress after each operation', () async {
      final run = executor.start(fs, plan);
      final events = <ExecutionProgress>[];
      run.progress.listen(events.add);
      await run.result;
      expect(events.map((e) => e.processed), [
        for (var i = 1; i <= plan.operations.length; i++) i,
      ]);
      expect(events.last.done, plan.operations.length);
      expect(events.map((e) => e.sessionId).toSet(), {run.sessionId});
    });

    test('planning again afterwards gives an empty plan', () async {
      await execute();
      expect((await PipelineHarness(fs).readyPlan()).isEmpty, isTrue);
    });
  });

  group('files changed after planning are skipped', () {
    setUp(() => setUpWith(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('a modified file', () async {
      fs.writeFile('Download/notes.txt', modifiedAt: DateTime.utc(2030));
      final session = await execute();

      final op = await journaled('Download/notes.txt');
      expect(op.status, OperationStatus.skipped);
      expect(op.error, const FileChanged());
      expect(fs.isFile('Download/notes.txt'), isTrue);
      expect(session.stats.skipped, 1);
      expect(session.stats.done, plan.operations.length - 1);
    });

    test('a file that is gone', () async {
      fs.removeExternally('Download/song.mp3');
      await execute();
      final op = await journaled('Download/song.mp3');
      expect(op.status, OperationStatus.skipped);
      expect(op.error, const FileGone());
    });

    test('a file replaced by a folder', () async {
      fs
        ..removeExternally('Download/song.mp3')
        ..addDir('Download/song.mp3');
      await execute();
      expect((await journaled('Download/song.mp3')).error, const NotAFile());
    });
  });

  group('file system errors', () {
    setUp(() => setUpWith(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('fail the operation, not the cleanup', () async {
      fs.failOn(
        FileErrorKind.ioError,
        methods: {FsMethod.move},
        path: 'Download/song.mp3',
      );
      final session = await execute();

      final op = await journaled('Download/song.mp3');
      expect(op.status, OperationStatus.failed);
      expect(
        op.error,
        const FileSystemError(FileErrorKind.ioError, detail: 'injected'),
      );
      expect(fs.isFile('Download/song.mp3'), isTrue);
      expect(session.status, SessionStatus.completed);
      expect(session.stats.failed, 1);
      expect(session.stats.done, plan.operations.length - 1);
    });

    test('a locked file', () async {
      fs.lock('Download/backup.zip');
      await execute();
      final op = await journaled('Download/backup.zip');
      expect(op.status, OperationStatus.failed);
      expect(op.error, const FileSystemError(FileErrorKind.locked));
    });

    test('a target taken after planning is never overwritten', () async {
      fs.addFile('Документы/notes.txt', text: 'someone else');
      await execute();
      expect(fs.readText('Документы/notes.txt'), 'someone else');
      final op = await journaled('Download/notes.txt');
      expect(op.status, OperationStatus.failed);
      expect(op.error, const FileSystemError(FileErrorKind.targetExists));
    });
  });

  group('dependent operations', () {
    setUp(() => setUpWith(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('a folder that cannot be created skips what goes into it', () async {
      fs.failOn(
        FileErrorKind.permissionDenied,
        methods: {FsMethod.mkdir},
        path: 'Фото',
      );
      final session = await execute();

      expect((await journaled('Фото')).status, OperationStatus.failed);
      for (final path in [
        'Фото/2023',
        'Фото/2024',
        'Download/photo.png',
        'Download/IMG_20240512_101500.jpg',
      ]) {
        final op = await journaled(path);
        expect(op.status, OperationStatus.skipped, reason: path);
        expect(op.error, DependsOnMissingFolder(LogicalPath('Фото')));
      }
      expect(fs.isFile('Download/photo.png'), isTrue);
      expect(fs.isDirectory('Документы'), isTrue, reason: 'others go on');
      expect(session.stats.failed, 1);
      expect(session.stats.skipped, 4);
    });

    test('a folder created meanwhile is used, not created', () async {
      fs.addDir('Документы');
      await execute();
      final mkdir = await journaled('Документы');
      expect(mkdir.status, OperationStatus.skipped);
      expect(mkdir.error, const FolderExists());
      expect(
        (await journaled('Download/notes.txt')).status,
        OperationStatus.done,
      );
    });

    test('a file where a folder should be blocks that folder', () async {
      fs.addFile('Музыка', text: 'not a folder');
      await execute();
      expect((await journaled('Музыка')).status, OperationStatus.failed);
      expect(
        (await journaled('Download/song.mp3')).status,
        OperationStatus.skipped,
      );
      expect(fs.readText('Музыка'), 'not a folder');
    });
  });

  group('duplicates are checked again before quarantine', () {
    const copy = 'Download/invoice_2024 (1).pdf';
    const kept = 'Download/invoice_2024.pdf';

    setUp(() => setUpWith(InMemoryFileSource()..withTypicalDownloadFolder()));

    /// Changes the content but keeps size and time, which the scan and the
    /// size/time check cannot see.
    void sneakyEdit(String path) {
      final text = fs.readText(path);
      final modified = fs.snapshot().files[path]!.modifiedAt;
      fs.writeFile(path, text: 'X' * text.length, modifiedAt: modified);
    }

    test('both full hashes are computed again', () async {
      await execute();
      final hashed = [
        for (final call in fs.calls)
          if (call.method == FsMethod.fullHash) call.path!.value,
      ];
      expect(hashed, containsAll([copy, kept]));
      expect((await journaled(copy)).status, OperationStatus.done);
    });

    test('a copy whose content changed stays', () async {
      sneakyEdit(copy);
      await execute();
      final op = await journaled(copy);
      expect(op.status, OperationStatus.skipped);
      expect(op.error, const NotADuplicate());
      expect(fs.isFile(copy), isTrue);
    });

    test('a copy whose original changed stays', () async {
      sneakyEdit(kept);
      await execute();
      final op = await journaled(copy);
      expect(op.status, OperationStatus.skipped);
      expect(op.error, KeeperChanged(LogicalPath(kept)));
      expect(fs.isFile(copy), isTrue);
    });

    test('a copy whose original is gone stays', () async {
      fs.removeExternally(kept);
      await execute();
      expect((await journaled(copy)).status, OperationStatus.skipped);
      expect(fs.isFile(copy), isTrue);
    });

    test('the original is found where this session moved it', () async {
      // Move the original first, then quarantine the copy.
      final reordered = Plan(
        operations: [
          ...plan.operations.where((o) => o.type != OperationType.quarantine),
          ...plan.operations.where((o) => o.type == OperationType.quarantine),
        ],
        duplicateGroups: plan.duplicateGroups,
      );
      await execute(reordered);
      expect((await journaled(copy)).status, OperationStatus.done);
      expect(fs.isFile('Документы/invoice_2024.pdf'), isTrue);
    });

    test('a quarantine outside any duplicate group is refused', () async {
      final orphan = Plan(
        operations: plan.operations.where(
          (o) => o.type == OperationType.quarantine,
        ),
      );
      await execute(orphan);
      final op = await journaled(copy);
      expect(op.status, OperationStatus.skipped);
      expect(op.error, const NotADuplicate());
      expect(fs.quarantined, isEmpty);
    });
  });

  test('iOS Photos: duplicates go to the album', () async {
    await setUpWith(
      InMemoryFileSource(capabilities: iosPhotosCapabilities)
        ..addFile('IMG_1.HEIC', text: 'same', modifiedAt: DateTime.utc(2020))
        ..addFile('IMG_2.HEIC', text: 'same', modifiedAt: DateTime.utc(2021)),
    );
    await execute();
    expect(fs.album, {LogicalPath('IMG_2.HEIC')});
    expect(fs.isFile('IMG_2.HEIC'), isTrue);
    final op = await journaled('IMG_2.HEIC');
    expect(op.status, OperationStatus.done);
    expect(op.quarantineRef, isNull);
  });

  group('cancellation', () {
    setUp(() => setUpWith(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('with batches of one, stops after the current operation', () async {
      executor = newExecutor(batchSize: 1);
      final run = executor.start(fs, plan);
      run.progress.listen((p) {
        if (p.processed == 3) {
          run.cancel();
        }
      });
      final session = await run.result;

      expect(session.status, SessionStatus.cancelled);
      final ops = await journal.bySession(session.id);
      expect(ops, hasLength(3));
      expect(ops.map((o) => o.status), everyElement(OperationStatus.done));
      expect(session.stats.total, 3);
      expect(fs.isFile('Download/song.mp3'), isTrue, reason: 'not reached');
    });

    test('stops at the end of the current batch', () async {
      executor = newExecutor(batchSize: 2);
      final run = executor.start(fs, plan);
      run.progress.listen((p) {
        if (p.processed == 3) {
          run.cancel();
        }
      });
      final session = await run.result;

      expect(session.status, SessionStatus.cancelled);
      final ops = await journal.bySession(session.id);
      // The third operation opens a batch of up to two: at most one more.
      expect(ops.length, inInclusiveRange(3, 4));
      expect(ops.map((o) => o.status), everyElement(OperationStatus.done));
      expect(session.stats.total, ops.length);
      expect(fs.isFile('Download/song.mp3'), isTrue, reason: 'not reached');
    });

    test('cancelling before the first operation does nothing', () async {
      final run = executor.start(fs, plan)..cancel();
      final before = fs.snapshot();
      final session = await run.result;
      expect(session.status, SessionStatus.cancelled);
      expect(await journal.bySession(session.id), isEmpty);
      expect(fs.snapshot(), before);
    });

    test('unsubscribing does not stop the cleanup', () async {
      final run = executor.start(fs, plan);
      await run.progress.first;
      final session = await run.result;
      expect(session.status, SessionStatus.completed);
      expect(session.stats.done, plan.operations.length);
    });
  });

  test('unapproved operations are neither journaled nor executed', () async {
    await setUpWith(InMemoryFileSource()..withTypicalDownloadFolder());
    final partial = Plan(
      operations: [
        for (final op in plan.operations)
          op.groupKey == 'move:Документы'
              ? op.withApproved(approved: false)
              : op,
      ],
      duplicateGroups: plan.duplicateGroups,
    );
    final session = await execute(partial);
    final ops = await journal.bySession(session.id);
    expect(ops.where((o) => o.groupKey == 'move:Документы'), isEmpty);
    expect(fs.isFile('Download/notes.txt'), isTrue);
    expect(session.stats.total, partial.approvedOperations.length);
  });

  group('a crash', () {
    setUp(() => setUpWith(InMemoryFileSource()..withTypicalDownloadFolder()));

    test('after the file system call leaves the operation pending', () async {
      executor = newExecutor(batchSize: 1);
      fs.crashOn(
        methods: {FsMethod.move},
        nth: 2,
        point: CrashPoint.afterEffect,
      );
      final run = executor.start(fs, plan);
      await expectLater(run.result, throwsA(isA<SimulatedCrash>()));

      final session = (await sessions.byId(run.sessionId))!;
      expect(session.status, SessionStatus.running);
      final ops = await journal.bySession(session.id);
      expect(ops.last.status, OperationStatus.pending);
      expect(ops.last.type, OperationType.move);
      expect(fs.isFile(ops.last.toPath!.value), isTrue, reason: 'moved');
      expect(
        ops.take(ops.length - 1).map((o) => o.status),
        everyElement(OperationStatus.done),
      );
    });

    test('in the middle of a batch leaves the whole batch pending', () async {
      fs.crashOn(
        methods: {FsMethod.move},
        nth: 2,
        point: CrashPoint.afterEffect,
      );
      final batches = _BatchJournal(journal);
      final run = newExecutor(using: batches).start(fs, plan);
      await expectLater(run.result, throwsA(isA<SimulatedCrash>()));

      final ops = await journal.bySession(run.sessionId);
      final last = batches.appended.last;
      expect(
        [
          for (final o in ops)
            if (o.status == OperationStatus.pending) o.id,
        ],
        last,
        reason: 'the batch of the crash, all of it',
      );
      expect(
        [
          for (final o in ops)
            if (o.status != OperationStatus.pending) o.status,
        ],
        everyElement(OperationStatus.done),
        reason: 'earlier batches',
      );
    });

    test('before the file system call leaves it pending, not done', () async {
      fs.crashOn(methods: {FsMethod.quarantine});
      final run = executor.start(fs, plan);
      await expectLater(run.result, throwsA(isA<SimulatedCrash>()));
      final ops = await journal.bySession(run.sessionId);
      expect(ops.single.status, OperationStatus.pending);
      expect(fs.isFile(ops.single.fromPath!.value), isTrue);
    });
  });

  test('invariant 3: each operation is journaled before it runs', () async {
    await setUpWith(InMemoryFileSource()..withTypicalDownloadFolder());
    final log = <String>[];
    final logged = _LoggingJournal(journal, log);
    fs.calls.clear();
    final source = _LoggingSource(fs, log);
    await newExecutor(using: logged).start(source, plan).result;

    final ops = await journal.bySession((await sessions.all()).single.id);
    for (final op in ops) {
      final pending = log.indexOf('pending ${op.id}');
      final finished = log.indexOf('${op.status.name} ${op.id}');
      final call = log.indexWhere(
        (e) =>
            e.startsWith('fs ') &&
            (e.endsWith(' ${op.fromPath ?? op.toPath}') ||
                e.endsWith(' ${op.toPath}')),
      );
      expect(pending, greaterThanOrEqualTo(0), reason: '${op.id}');
      expect(call, greaterThan(pending), reason: 'fs call of ${op.id}');
      expect(finished, greaterThan(call), reason: 'result of ${op.id}');
    }
  });

  group('batches', () {
    test('up to the batch size; a quarantine is a batch of its own', () async {
      await setUpWith(
        InMemoryFileSource()
          ..withTypicalDownloadFolder()
          ..withNotes(70),
      );
      final batches = _BatchJournal(journal);
      await newExecutor(using: batches).start(fs, plan).result;
      final ops = {
        for (final o in await journal.bySession(
          (await sessions.all()).single.id,
        ))
          o.id: o,
      };

      expect(batches.appended, isNotEmpty);
      expect(
        [for (final b in batches.appended) b.length].reduce(math.max),
        Executor.defaultBatchSize,
      );
      for (final batch in batches.appended) {
        final types = [for (final id in batch) ops[id]!.type];
        if (types.any(
          (t) => t == OperationType.quarantine || t == OperationType.addToAlbum,
        )) {
          expect(types, hasLength(1), reason: 'alone: $types');
        }
        final seqs = [for (final id in batch) ops[id]!.seq];
        expect(seqs, [for (var i = 0; i < seqs.length; i++) seqs.first + i]);
      }
      expect(batches.appended.expand((b) => b).toList(), [
        for (final o in ops.values) o.id,
      ], reason: 'every operation once, in plan order');
      expect(batches.updated, batches.appended, reason: 'results per batch');
    });

    test('a quarantine after moves still runs alone', () async {
      // The planner puts duplicates first; the executor must not rely on it.
      await setUpWith(InMemoryFileSource()..withTypicalDownloadFolder());
      bool alone(PlannedOperation o) =>
          o.type == OperationType.quarantine ||
          o.type == OperationType.addToAlbum;
      final reordered = Plan(
        operations: [
          ...plan.operations.where((o) => !alone(o)),
          ...plan.operations.where(alone),
        ],
        unresolved: plan.unresolved,
        duplicateGroups: plan.duplicateGroups,
      );
      final batches = _BatchJournal(journal);
      final session = await newExecutor(using: batches)
          .start(fs, reordered)
          .result;
      final ops = {
        for (final o in await journal.bySession(session.id)) o.id: o,
      };
      final quarantines = [
        for (final o in ops.values)
          if (o.type == OperationType.quarantine) o.id,
      ];
      expect(quarantines, isNotEmpty);
      for (final batch in batches.appended) {
        if (batch.any(quarantines.contains)) {
          expect(batch, hasLength(1));
        }
      }
      expect(
        ops.values.map((o) => o.status),
        everyElement(OperationStatus.done),
      );
    });

    test('a batch size below one is refused', () {
      expect(() => newExecutor(batchSize: 0), throwsArgumentError);
    });
  });

  test('a plan of another source is refused', () async {
    await setUpWith(InMemoryFileSource()..withTypicalDownloadFolder());
    final other = InMemoryFileSource(sourceId: const SourceId('other'));
    expect(() => executor.start(other, plan), throwsArgumentError);
  });
}

/// Records journal writes in a shared log.
final class _LoggingJournal implements OperationJournal {
  _LoggingJournal(this._inner, this._log);

  final OperationJournal _inner;
  final List<String> _log;

  @override
  Future<void> append(Operation operation) async {
    await _inner.append(operation);
    _log.add('pending ${operation.id}');
  }

  @override
  Future<void> update(Operation operation) async {
    await _inner.update(operation);
    _log.add('${operation.status.name} ${operation.id}');
  }

  @override
  Future<void> appendAll(List<Operation> operations) async {
    await _inner.appendAll(operations);
    _log.addAll([for (final o in operations) 'pending ${o.id}']);
  }

  @override
  Future<void> updateAll(List<Operation> operations) async {
    await _inner.updateAll(operations);
    _log.addAll([for (final o in operations) '${o.status.name} ${o.id}']);
  }

  @override
  Future<Operation?> byId(OperationId id) => _inner.byId(id);

  @override
  Future<List<Operation>> doneQuarantinesBefore(DateTime cutoff) =>
      _inner.doneQuarantinesBefore(cutoff);

  @override
  Future<List<Operation>> bySession(
    SessionId sessionId, {
    String? groupKey,
    bool reverse = false,
  }) => _inner.bySession(sessionId, groupKey: groupKey, reverse: reverse);
}

/// Records changing file system calls in a shared log.
final class _LoggingSource implements FileSource {
  _LoggingSource(this._inner, this._log);

  final InMemoryFileSource _inner;
  final List<String> _log;

  Future<FileResult<T>> _logged<T>(
    String what,
    LogicalPath path,
    Future<FileResult<T>> call,
  ) {
    _log.add('fs $what $path');
    return call;
  }

  @override
  SourceId get sourceId => _inner.sourceId;

  @override
  SourceCapabilities get capabilities => _inner.capabilities;

  @override
  Set<LogicalPath> get appFolders => _inner.appFolders;

  @override
  Stream<FileResult<FileListPage>> list({
    ScanCursor? after,
    bool Function(LogicalPath folder)? skipFolder,
  }) => _inner.list(after: after, skipFolder: skipFolder);

  @override
  Future<FileResult<FileStat>> stat(LogicalPath path) => _inner.stat(path);

  @override
  Future<FileResult<bool>> exists(LogicalPath path) => _inner.exists(path);

  @override
  Future<FileResult<String>> partialHash(
    LogicalPath path, {
    CancelToken? cancel,
  }) => _inner.partialHash(path, cancel: cancel);

  @override
  Future<FileResult<String>> fullHash(
    LogicalPath path, {
    CancelToken? cancel,
  }) => _inner.fullHash(path, cancel: cancel);

  @override
  Future<FileResult<void>> mkdir(LogicalPath path) =>
      _logged('mkdir', path, _inner.mkdir(path));

  @override
  Future<FileResult<void>> move(LogicalPath from, LogicalPath to) =>
      _logged('move', from, _inner.move(from, to));

  @override
  Future<FileResult<QuarantineRef>> quarantine(
    LogicalPath path,
    SessionId sessionId,
  ) => _logged('quarantine', path, _inner.quarantine(path, sessionId));

  @override
  Future<FileResult<QuarantineRef?>> findQuarantined(
    SessionId sessionId,
    LogicalPath original,
  ) => _inner.findQuarantined(sessionId, original);

  @override
  Future<FileResult<void>> restore(QuarantineRef ref, LogicalPath to) =>
      _logged('restore', to, _inner.restore(ref, to));

  @override
  Future<FileResult<void>> removeEmptyDir(LogicalPath path) =>
      _logged('removeEmptyDir', path, _inner.removeEmptyDir(path));

  @override
  Future<FileResult<void>> purgeQuarantined(QuarantineRef ref) =>
      _inner.purgeQuarantined(ref);

  @override
  Future<FileResult<void>> addToAlbum(LogicalPath path) =>
      _logged('addToAlbum', path, _inner.addToAlbum(path));

  @override
  Future<FileResult<void>> removeFromAlbum(LogicalPath path) =>
      _logged('removeFromAlbum', path, _inner.removeFromAlbum(path));
}

/// Records which operations each batch write carried.
final class _BatchJournal implements OperationJournal {
  _BatchJournal(this._inner);

  final OperationJournal _inner;
  final List<List<OperationId>> appended = [];
  final List<List<OperationId>> updated = [];

  @override
  Future<void> append(Operation operation) => appendAll([operation]);

  @override
  Future<void> update(Operation operation) => updateAll([operation]);

  @override
  Future<void> appendAll(List<Operation> operations) async {
    await _inner.appendAll(operations);
    appended.add([for (final o in operations) o.id]);
  }

  @override
  Future<void> updateAll(List<Operation> operations) async {
    await _inner.updateAll(operations);
    updated.add([for (final o in operations) o.id]);
  }

  @override
  Future<Operation?> byId(OperationId id) => _inner.byId(id);

  @override
  Future<List<Operation>> doneQuarantinesBefore(DateTime cutoff) =>
      _inner.doneQuarantinesBefore(cutoff);

  @override
  Future<List<Operation>> bySession(
    SessionId sessionId, {
    String? groupKey,
    bool reverse = false,
  }) => _inner.bySession(sessionId, groupKey: groupKey, reverse: reverse);
}
