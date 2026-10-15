import 'dart:io';

import 'package:drift/native.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/db/sqlite_setup.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's database settings (`docs/stage2_android.md`, 5.27), on a real
/// database file: WAL, and every commit synced.
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sqlite_setup');
    db = AppDatabase(
      NativeDatabase(File('${dir.path}/app.sqlite'), setup: configureSqlite),
    );
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<Object?> pragma(String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).data.values.single;

  test('the journal is a write-ahead log', () async {
    expect(await pragma('journal_mode'), 'wal');
  });

  test('every commit is synced to the disk (FULL, not NORMAL)', () async {
    // 0 OFF, 1 NORMAL, 2 FULL, 3 EXTRA.
    expect(await pragma('synchronous'), 2);
  });

  test('the database works with these settings', () async {
    await db.customStatement('CREATE TABLE t (x INTEGER)');
    await db.customStatement('INSERT INTO t VALUES (1)');
    expect(
      (await db.customSelect('SELECT x FROM t').getSingle()).read<int>('x'),
      1,
    );
  });
}
