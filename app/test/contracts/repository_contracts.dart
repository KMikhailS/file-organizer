import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/model_fixtures.dart';

/// Behavior every [SourceRepository] implementation must have.
void sourceRepositoryContract(Future<SourceRepository> Function() create) {
  late SourceRepository repo;
  setUp(() async => repo = await create());

  Source source(String id, {bool enabled = true}) => Source(
    id: SourceId(id),
    kind: SourceKind.desktopFolder,
    displayName: 'Source $id',
    capabilities: const SourceCapabilities(canMove: true),
    enabled: enabled,
  );

  test('starts empty', () async {
    expect(await repo.all(), isEmpty);
    expect(await repo.byId(const SourceId('x')), isNull);
  });

  test('saves, finds and lists sorted by id', () async {
    await repo.save(source('b'));
    await repo.save(source('a'));
    expect(await repo.byId(const SourceId('a')), source('a'));
    expect(await repo.all(), [source('a'), source('b')]);
  });

  test('save replaces the source with the same id', () async {
    await repo.save(source('a'));
    await repo.save(source('a', enabled: false));
    expect(await repo.all(), [source('a', enabled: false)]);
  });
}

/// Behavior every [FileIndexRepository] implementation must have.
void fileIndexRepositoryContract(
  Future<FileIndexRepository> Function() create,
) {
  late FileIndexRepository repo;
  setUp(() async => repo = await create());

  const other = SourceId('other');
  const scan1 = ScanId('scan-1');
  const scan2 = ScanId('scan-2');

  test('starts empty', () async {
    expect(await repo.bySource(testSource), isEmpty);
    expect(await repo.byPath(testSource, p('a')), isNull);
    expect(await repo.sizesWithMultipleFiles(testSource), isEmpty);
  });

  test('stores every field and finds by path', () async {
    final entry = fileEntry(
      'Download/IMG_1.jpg',
      size: 10,
      capturedAt: DateTime.utc(2023, 5, 6, 7, 8, 9, 10, 11),
      modifiedAt: DateTime.utc(2024, 1, 2, 3, 4, 5, 6, 7),
      mimeType: 'image/jpeg',
      partialHash: 'p',
      fullHash: 'f',
      lastSeenScanId: scan1,
    );
    await repo.upsertAll([entry]);
    expect(await repo.byPath(testSource, entry.path), entry);
  });

  test('finds several paths at once', () async {
    await repo.upsertAll([
      fileEntry('a', size: 1),
      fileEntry('b', size: 2),
      fileEntry('c', sourceId: other, size: 3),
    ]);
    final found = await repo.byPaths(testSource, [p('a'), p('c'), p('x')]);
    expect(found, {p('a'): fileEntry('a', size: 1)});
    expect(await repo.byPaths(testSource, const []), isEmpty);
  });

  test('upsert replaces by source and path', () async {
    await repo.upsertAll([fileEntry('a', fullHash: 'old')]);
    await repo.upsertAll([fileEntry('a', fullHash: 'new')]);
    expect(await repo.bySource(testSource), [fileEntry('a', fullHash: 'new')]);
  });

  test('keeps sources apart', () async {
    await repo.upsertAll([
      fileEntry('a', size: 5),
      fileEntry('a', sourceId: other, size: 7),
    ]);
    expect((await repo.byPath(testSource, p('a')))!.size, 5);
    expect((await repo.byPath(other, p('a')))!.size, 7);
    expect(await repo.bySource(other), [
      fileEntry('a', sourceId: other, size: 7),
    ]);
  });

  test('lists by source sorted by path', () async {
    await repo.upsertAll([fileEntry('b'), fileEntry('a/z'), fileEntry('a')]);
    expect((await repo.bySource(testSource)).map((e) => e.path.value), [
      'a',
      'a/z',
      'b',
    ]);
  });

  test('paths are case-sensitive keys', () async {
    await repo.upsertAll([fileEntry('a.jpg'), fileEntry('A.jpg')]);
    expect(await repo.bySource(testSource), hasLength(2));
  });

  test('finds sizes shared by several files and files by size', () async {
    await repo.upsertAll([
      fileEntry('a', size: 10),
      fileEntry('b', size: 10),
      fileEntry('c', size: 20),
      fileEntry('d', size: 0),
      fileEntry('e', size: 0),
      fileEntry('f', sourceId: other, size: 20),
    ]);
    expect(await repo.sizesWithMultipleFiles(testSource), [0, 10]);
    expect((await repo.bySize(testSource, 10)).map((e) => e.path.value), [
      'a',
      'b',
    ]);
    expect(await repo.bySize(testSource, 30), isEmpty);
  });

  test('finds files by full hash within a source', () async {
    await repo.upsertAll([
      fileEntry('b', fullHash: 'h'),
      fileEntry('a', fullHash: 'h'),
      fileEntry('c', fullHash: 'x'),
      fileEntry('d'),
      fileEntry('e', sourceId: other, fullHash: 'h'),
    ]);
    expect((await repo.byFullHash(testSource, 'h')).map((e) => e.path.value), [
      'a',
      'b',
    ]);
  });

  test('removes entries not seen in a scan, only in that source', () async {
    await repo.upsertAll([
      fileEntry('seen', lastSeenScanId: scan2),
      fileEntry('old', lastSeenScanId: scan1),
      fileEntry('never'),
      fileEntry('elsewhere', sourceId: other, lastSeenScanId: scan1),
    ]);
    expect(await repo.removeNotSeenIn(testSource, scan2), 2);
    expect((await repo.bySource(testSource)).map((e) => e.path.value), [
      'seen',
    ]);
    expect(await repo.bySource(other), hasLength(1));
    expect(await repo.removeNotSeenIn(testSource, scan2), 0);
  });
}

/// Behavior every [ScanCheckpointRepository] implementation must have.
void scanCheckpointRepositoryContract(
  Future<ScanCheckpointRepository> Function() create,
) {
  late ScanCheckpointRepository repo;
  setUp(() async => repo = await create());

  ScanCheckpoint checkpoint({
    SourceId sourceId = testSource,
    ScanStage stage = ScanStage.listing,
    String? cursor,
  }) => ScanCheckpoint(
    sourceId: sourceId,
    scanId: const ScanId('scan-1'),
    stage: stage,
    cursor: cursor == null ? null : ScanCursor(cursor),
  );

  test('saves, replaces and clears per source', () async {
    expect(await repo.bySource(testSource), isNull);

    await repo.save(checkpoint());
    await repo.save(checkpoint(sourceId: const SourceId('other'), cursor: 'x'));
    expect(await repo.bySource(testSource), checkpoint());

    await repo.save(checkpoint(stage: ScanStage.finalizing, cursor: 'c'));
    expect(
      await repo.bySource(testSource),
      checkpoint(stage: ScanStage.finalizing, cursor: 'c'),
    );

    await repo.clear(testSource);
    expect(await repo.bySource(testSource), isNull);
    expect(
      await repo.bySource(const SourceId('other')),
      checkpoint(sourceId: const SourceId('other'), cursor: 'x'),
    );
  });
}

/// Behavior every [SessionRepository] implementation must have.
void sessionRepositoryContract(Future<SessionRepository> Function() create) {
  late SessionRepository repo;
  setUp(() async => repo = await create());

  final end = testTime.add(const Duration(minutes: 3));

  CleanupSession planned(String id, {DateTime? startedAt}) => CleanupSession(
    id: SessionId(id),
    startedAt: startedAt ?? testTime,
    status: SessionStatus.planned,
    stats: SessionStats.empty,
  );

  test('saves and finds every field', () async {
    final session = planned('s1')
        .transitionTo(SessionStatus.running)
        .transitionTo(SessionStatus.completed, finishedAt: end)
        .withStats(
          SessionStats(
            total: 3,
            done: 2,
            failed: 1,
            skipped: 0,
            reverted: 0,
            revertSkipped: 0,
            removedBytes: 99,
          ),
        );
    await repo.save(session);
    expect(await repo.byId(const SessionId('s1')), session);
    expect(await repo.byId(const SessionId('nope')), isNull);
  });

  test('lists newest first, then by id', () async {
    await repo.save(planned('a'));
    await repo.save(planned('c', startedAt: end));
    await repo.save(planned('b'));
    expect((await repo.all()).map((s) => s.id.value), ['c', 'b', 'a']);
  });

  test('finds by status', () async {
    await repo.save(planned('a'));
    await repo.save(planned('b').transitionTo(SessionStatus.running));
    expect((await repo.byStatus(SessionStatus.running)).map((s) => s.id), [
      const SessionId('b'),
    ]);
  });

  test('replacement follows the allowed transitions', () async {
    final session = planned('s');
    await repo.save(session);
    final running = session.transitionTo(SessionStatus.running);
    await repo.save(running);
    await repo.save(running.withStats(SessionStats.empty));
    final completed = running.transitionTo(
      SessionStatus.completed,
      finishedAt: end,
    );
    await repo.save(completed);
    expect(await repo.byId(session.id), completed);

    // Back to running is not an allowed transition.
    await expectLater(repo.save(running), throwsStateError);
    expect(await repo.byId(session.id), completed);
  });

  test('replacement keeps startedAt and finishedAt', () async {
    await repo.save(planned('s'));
    await expectLater(
      repo.save(planned('s', startedAt: end)),
      throwsStateError,
    );

    final completed = planned('s')
        .transitionTo(SessionStatus.running)
        .transitionTo(SessionStatus.completed, finishedAt: end);
    final otherFinish = planned('s')
        .transitionTo(SessionStatus.running)
        .transitionTo(SessionStatus.completed, finishedAt: testTime);
    await repo.save(planned('s').transitionTo(SessionStatus.running));
    await repo.save(completed);
    await expectLater(repo.save(otherFinish), throwsStateError);
  });
}

/// Behavior every [OperationJournal] implementation must have.
void operationJournalContract(Future<OperationJournal> Function() create) {
  late OperationJournal journal;
  setUp(() async => journal = await create());

  const s1 = SessionId('s1');
  const s2 = SessionId('s2');
  final at = testTime;
  final later = testTime.add(const Duration(hours: 1));

  Operation pending(
    String id, {
    SessionId session = s1,
    int seq = 0,
    PlannedOperation? planned,
  }) => Operation.pending(
    id: OperationId(id),
    sessionId: session,
    seq: seq,
    planned: planned ?? plannedMove('a$seq.pdf', 'Documents/a$seq.pdf'),
  );

  test('appends and finds every field', () async {
    final op = pending('o1', planned: plannedQuarantine('x (1).pdf'));
    await journal.append(op);
    expect(await journal.byId(op.id), op);
    expect(await journal.byId(const OperationId('nope')), isNull);
  });

  test('appends only pending operations', () async {
    final done = pending('o1').markDone(at: at);
    await expectLater(journal.append(done), throwsStateError);
    expect(await journal.byId(done.id), isNull);
  });

  test('rejects a duplicate id or seq', () async {
    await journal.append(pending('o1'));
    await expectLater(journal.append(pending('o1', seq: 1)), throwsStateError);
    await expectLater(journal.append(pending('o2')), throwsStateError);
    // The same seq in another session is fine.
    await journal.append(pending('o3', session: s2));
  });

  test('updates by allowed transitions and keeps every field', () async {
    final op = pending('o1', planned: plannedQuarantine('x (1).pdf'));
    await journal.append(op);
    final done = op.markDone(at: at, quarantineRef: QuarantineRef('q'));
    await journal.update(done);
    expect(await journal.byId(op.id), done);

    final skipped = done.markRevertSkipped(reason: 'target occupied');
    await journal.update(skipped);
    final reverted = skipped.markReverted(at: later);
    await journal.update(reverted);
    expect(await journal.byId(op.id), reverted);
  });

  test('rejects updates of unknown operations', () async {
    await expectLater(
      journal.update(pending('o1').markDone(at: at)),
      throwsStateError,
    );
  });

  test('rejects transitions that are not allowed', () async {
    final op = pending('o1');
    await journal.append(op);
    final done = op.markDone(at: at);
    await journal.update(done);

    // A stale copy cannot bring a done operation back or fail it.
    await expectLater(journal.update(op), throwsStateError);
    await expectLater(
      journal.update(op.markFailed(at: at, error: 'e')),
      throwsStateError,
    );
    // The same status twice is not a transition either.
    await expectLater(journal.update(done), throwsStateError);
    expect(await journal.byId(op.id), done);
  });

  test('rejects changes to anything but the status', () async {
    final op = pending('o1');
    await journal.append(op);
    final rewritten = Operation.pending(
      id: op.id,
      sessionId: s1,
      seq: 0,
      planned: plannedMove('a0.pdf', 'Elsewhere/a0.pdf'),
    ).markDone(at: at);
    await expectLater(journal.update(rewritten), throwsStateError);
    expect(await journal.byId(op.id), op);
  });

  test('rejects changing recorded execution data', () async {
    final op = pending('o1');
    await journal.append(op);
    await journal.update(op.markDone(at: at));
    final otherTime = op.markDone(at: later).markReverted(at: later);
    await expectLater(journal.update(otherTime), throwsStateError);
  });

  test('finds done quarantines executed before a time', () async {
    final t0 = DateTime.utc(2024);
    Future<void> add(
      String id,
      PlannedOperation planned, {
      DateTime? doneAt,
    }) async {
      final op = Operation.pending(
        id: OperationId(id),
        sessionId: id.startsWith('b') ? s2 : s1,
        seq: int.parse(id.substring(1)),
        planned: planned,
      );
      await journal.append(op);
      if (doneAt != null) {
        await journal.update(
          planned.type == OperationType.quarantine
              ? op.markDone(at: doneAt, quarantineRef: QuarantineRef('q$id'))
              : op.markDone(at: doneAt),
        );
      }
    }

    await add('a1', plannedQuarantine('old.pdf'), doneAt: t0);
    await add(
      'b2',
      plannedQuarantine('older.pdf'),
      doneAt: t0.subtract(const Duration(days: 1)),
    );
    await add(
      'a3',
      plannedQuarantine('new.pdf'),
      doneAt: t0.add(const Duration(days: 40)),
    );
    await add('a4', plannedQuarantine('pending.pdf'));
    await add('a5', plannedMove('m.pdf', 'Documents/m.pdf'), doneAt: t0);
    final reverted = Operation.pending(
      id: const OperationId('a6'),
      sessionId: s1,
      seq: 6,
      planned: plannedQuarantine('back.pdf'),
    );
    await journal.append(reverted);
    final done = reverted.markDone(at: t0, quarantineRef: QuarantineRef('q6'));
    await journal.update(done);
    await journal.update(done.markReverted(at: t0));

    final cutoff = t0.add(const Duration(days: 30));
    expect(
      (await journal.doneQuarantinesBefore(cutoff)).map((o) => o.id.value),
      ['b2', 'a1'],
    );
    expect(
      await journal.doneQuarantinesBefore(t0.subtract(const Duration(days: 2))),
      isEmpty,
    );
  });

  group('bySession', () {
    setUp(() async {
      await journal.append(
        pending('c', seq: 2, planned: plannedQuarantine('d.pdf')),
      );
      await journal.append(pending('a', planned: plannedMkdir('Documents')));
      await journal.append(pending('b', seq: 1));
      await journal.append(pending('x', session: s2));
    });

    test('orders by seq', () async {
      expect((await journal.bySession(s1)).map((o) => o.id.value), [
        'a',
        'b',
        'c',
      ]);
    });

    test('orders by seq in reverse', () async {
      expect(
        (await journal.bySession(s1, reverse: true)).map((o) => o.id.value),
        ['c', 'b', 'a'],
      );
    });

    test('filters by group', () async {
      expect(
        (await journal.bySession(s1, groupKey: 'move')).map((o) => o.id.value),
        ['a', 'b'],
      );
      expect(
        (await journal.bySession(
          s1,
          groupKey: 'duplicates',
          reverse: true,
        )).map((o) => o.id.value),
        ['c'],
      );
    });

    test('is empty for an unknown session', () async {
      expect(await journal.bySession(const SessionId('none')), isEmpty);
    });
  });
}

/// Behavior every [RuleRepository] implementation must have.
void ruleRepositoryContract(Future<RuleRepository> Function() create) {
  late RuleRepository repo;
  setUp(() async => repo = await create());

  const other = SourceId('other');

  ZoneOverride mark(
    String folder,
    Zone zone, {
    SourceId sourceId = testSource,
  }) => ZoneOverride(sourceId: sourceId, folder: p(folder), zone: zone);

  test('starts without zone overrides', () async {
    expect(await repo.zoneOverrides(testSource), isEmpty);
  });

  test('saves zone overrides per source, sorted by folder', () async {
    await repo.saveZoneOverride(mark('b', Zone.chaos));
    await repo.saveZoneOverride(mark('', Zone.organized));
    await repo.saveZoneOverride(mark('a/x', Zone.excluded));
    await repo.saveZoneOverride(mark('b', Zone.chaos, sourceId: other));
    expect(await repo.zoneOverrides(testSource), [
      mark('', Zone.organized),
      mark('a/x', Zone.excluded),
      mark('b', Zone.chaos),
    ]);
    expect(await repo.zoneOverrides(other), [
      mark('b', Zone.chaos, sourceId: other),
    ]);
  });

  test('replaces the override of the same folder', () async {
    await repo.saveZoneOverride(mark('a', Zone.chaos));
    await repo.saveZoneOverride(mark('a', Zone.excluded));
    expect(await repo.zoneOverrides(testSource), [mark('a', Zone.excluded)]);
  });

  test('removes an override, ignoring unknown ones', () async {
    await repo.saveZoneOverride(mark('a', Zone.chaos));
    await repo.saveZoneOverride(mark('a', Zone.chaos, sourceId: other));
    await repo.removeZoneOverride(testSource, p('a'));
    await repo.removeZoneOverride(testSource, p('missing'));
    expect(await repo.zoneOverrides(testSource), isEmpty);
    expect(await repo.zoneOverrides(other), hasLength(1));
  });

  group('classification rules', () {
    ClassificationRule rule(
      String id, {
      int priority = 0,
      Category category = Category.documents,
    }) => ClassificationRule(
      id: id,
      category: category,
      priority: priority,
      extensions: const {'dwg', 'DXF'},
      nameContains: 'Plan',
      folder: p('Work'),
      sourceId: testSource,
    );

    test('start empty', () async {
      expect(await repo.classificationRules(), isEmpty);
    });

    test('are stored with every field, by priority then id', () async {
      await repo.saveClassificationRule(rule('b', priority: 1));
      await repo.saveClassificationRule(rule('c'));
      await repo.saveClassificationRule(rule('a', priority: 1));
      await repo.saveClassificationRule(
        ClassificationRule(
          id: 'd',
          category: Category.other,
          priority: -1,
          extensions: const {'x'},
        ),
      );
      expect((await repo.classificationRules()).map((r) => r.id), [
        'd',
        'c',
        'a',
        'b',
      ]);
      expect((await repo.classificationRules())[1], rule('c'));
    });

    test('are replaced by id and removed', () async {
      await repo.saveClassificationRule(rule('a'));
      await repo.saveClassificationRule(
        rule('a', category: Category.unresolved),
      );
      expect(await repo.classificationRules(), [
        rule('a', category: Category.unresolved),
      ]);
      await repo.removeClassificationRule('a');
      await repo.removeClassificationRule('missing');
      expect(await repo.classificationRules(), isEmpty);
    });
  });
}

/// Behavior every [SettingsRepository] implementation must have.
void settingsRepositoryContract(Future<SettingsRepository> Function() create) {
  late SettingsRepository repo;
  setUp(() async => repo = await create());

  test('gives the defaults before anything is saved', () async {
    expect(await repo.load(), Settings());
    expect(
      (await repo.load()).quarantineRetention,
      Settings.defaultQuarantineRetention,
    );
  });

  test('saves and replaces the settings', () async {
    await repo.save(Settings(quarantineRetention: const Duration(days: 7)));
    expect(
      await repo.load(),
      Settings(quarantineRetention: const Duration(days: 7)),
    );
    await repo.save(Settings(quarantineRetention: const Duration(days: 90)));
    expect((await repo.load()).quarantineRetention, const Duration(days: 90));
  });
}
