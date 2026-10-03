import 'dart:io';

import 'package:drift/native.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/model_fixtures.dart';

// These tests use a real SQLite file on disk on purpose: they check the
// data layer, not the core.
void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  test('creates every table of schema version 1', () async {
    expect(db.schemaVersion, 1);
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(
      rows.map((r) => r.read<String>('name')).toSet(),
      containsAll([
        'sources',
        'file_index',
        'scan_checkpoints',
        'sessions',
        'operations',
        'zone_overrides',
        'classification_rules',
        'settings',
      ]),
    );
  });

  test('data survives closing and reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp('file_organizer_db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    final entry = fileEntry('Download/a.pdf', fullHash: 'h');
    await DriftFileIndexRepository(first).upsertAll([entry]);
    await DriftSettingsRepository(first)
        .save(Settings(quarantineRetention: const Duration(days: 9)));
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    expect(await DriftFileIndexRepository(second).bySource(testSource), [
      entry,
    ]);
    expect(
      (await DriftSettingsRepository(second).load()).quarantineRetention,
      const Duration(days: 9),
    );
  });

  test('dates keep their microseconds and come back in UTC', () async {
    final repo = DriftFileIndexRepository(db);
    final precise = DateTime.utc(2024, 2, 29, 23, 59, 59, 999, 999);
    await repo.upsertAll([
      fileEntry('a', modifiedAt: precise, capturedAt: precise.toLocal()),
    ]);
    final stored = (await repo.byPath(testSource, LogicalPath('a')))!;
    expect(stored.modifiedAt, precise);
    expect(stored.modifiedAt.isUtc, isTrue);
    expect(stored.capturedAt, precise);
    expect(stored.fingerprint, fileEntry('a', modifiedAt: precise).fingerprint);
  });

  test('enums are stored by name', () async {
    final journal = DriftOperationJournal(db);
    await journal.append(
      Operation.pending(
        id: const OperationId('o1'),
        sessionId: const SessionId('s1'),
        seq: 0,
        planned: plannedQuarantine('a.pdf'),
      ),
    );
    final row = await db
        .customSelect('SELECT type, status FROM operations')
        .getSingle();
    expect(row.read<String>('type'), 'quarantine');
    expect(row.read<String>('status'), 'pending');
  });

  test(
    'paths are sorted the way the core sorts them, emoji included',
    () async {
      final repo = DriftFileIndexRepository(db);
      final paths = ['a\u{1F600}.jpg', 'a�.jpg', 'A.jpg', 'a.jpg', 'ä.jpg'];
      await repo.upsertAll(paths.map(fileEntry));
      final expected = paths.map(LogicalPath.new).toList()..sort();
      expect((await repo.bySource(testSource)).map((e) => e.path), expected);
    },
  );

  test('byPaths handles more paths than one query can take', () async {
    final repo = DriftFileIndexRepository(db);
    final entries = [for (var i = 0; i < 1234; i++) fileEntry('f$i')];
    await repo.upsertAll(entries);
    final found = await repo.byPaths(testSource, [
      for (final e in entries) e.path,
      LogicalPath('missing'),
    ]);
    expect(found, hasLength(1234));
    expect(found[LogicalPath('f777')], entries[777]);
  });

  test('a rejected journal write leaves nothing behind', () async {
    final journal = DriftOperationJournal(db);
    final op = Operation.pending(
      id: const OperationId('o1'),
      sessionId: const SessionId('s1'),
      seq: 0,
      planned: plannedMove('a.pdf', 'Документы/a.pdf'),
    );
    await journal.append(op);
    final done = op.markDone(at: testTime);
    await journal.update(done);
    await expectLater(
      journal.update(op.markFailed(at: testTime, error: 'x')),
      throwsStateError,
    );
    expect(await journal.byId(op.id), done);
    final count = await db
        .customSelect('SELECT COUNT(*) AS n FROM operations')
        .getSingle();
    expect(count.read<int>('n'), 1);
  });
}
