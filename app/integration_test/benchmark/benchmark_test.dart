// Where the time of one cleanup operation goes on a device
// (docs/stage2_android.md, 5.27): the journal's two transactions per
// operation in each SQLite mode, and stat + move through the real adapter
// on the test root. Run it with run_android.sh, never on its own: the
// script grants the access and removes the test root and the app.
//
// Prints BENCH|<name>=<value> lines (microseconds per operation).
import 'dart:io';

import 'package:drift/native.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/drift_operation_journal.dart';
import 'package:file_organizer/platform/android/android_file_source.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/platform/android/test_root_storage.dart';
import 'package:file_organizer/platform/services/system_clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String root = '/storage/emulated/0/FileOrganizerTest';
const int count = 300;

void say(String name, Object value) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('BENCH|$name=$value');
}

PlannedOperation _move(int i) => PlannedOperation.move(
  sourceId: const SourceId('bench'),
  from: LogicalPath('a/f_$i.txt'),
  to: LogicalPath('b/f_$i.txt'),
  fingerprint: Fingerprint(size: 10, modifiedAt: DateTime.utc(2024)),
  reason: const Classified(ByExtension('txt')),
  groupKey: 'bench',
  approved: true,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final (mode, pragmas) in [
    ('delete_full', <String>[]),
    ('wal_full', ['PRAGMA journal_mode = WAL', 'PRAGMA synchronous = FULL']),
    (
      'wal_normal',
      ['PRAGMA journal_mode = WAL', 'PRAGMA synchronous = NORMAL'],
    ),
  ]) {
    test('journal, $mode', () async {
      final dir = await Directory.systemTemp.createTemp('bench');
      addTearDown(() => dir.delete(recursive: true));
      final db = AppDatabase(
        NativeDatabase.createBackgroundConnection(
          File('${dir.path}/bench.sqlite'),
          setup: (raw) {
            for (final pragma in pragmas) {
              raw.execute(pragma);
            }
          },
        ),
      );
      addTearDown(db.close);
      final journal = DriftOperationJournal(db);
      // Warm up: the schema is created on the first query.
      await journal.bySession(const SessionId('none'));
      final clock = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        final op = Operation.pending(
          id: OperationId('o$i'),
          sessionId: const SessionId('s'),
          seq: i,
          planned: _move(i),
        );
        await journal.append(op);
        await journal.update(op.markDone(at: DateTime.now().toUtc()));
      }
      clock.stop();
      say('journal_${mode}_us', clock.elapsedMicroseconds ~/ count);
    });
  }

  test('stat and move through the adapter', () async {
    final a = Directory('$root/a')..createSync(recursive: true);
    Directory('$root/b').createSync();
    for (var i = 0; i < count; i++) {
      File('${a.path}/f_$i.txt').writeAsStringSync('note $i\n');
    }
    final source = await AndroidFileSource.open(
      sourceId: const SourceId('bench'),
      root: root,
      clock: const SystemClock(),
      native: AndroidNative(storage: TestRootStorage(root)),
    );
    final stats = Stopwatch();
    final moves = Stopwatch();
    for (var i = 0; i < count; i++) {
      stats.start();
      expect((await source.stat(LogicalPath('a/f_$i.txt'))).isSuccess, isTrue);
      stats.stop();
      moves.start();
      final moved = await source.move(
        LogicalPath('a/f_$i.txt'),
        LogicalPath('b/f_$i.txt'),
      );
      moves.stop();
      expect(moved.isSuccess, isTrue, reason: '$moved');
    }
    say('stat_us', stats.elapsedMicroseconds ~/ count);
    say('move_us', moves.elapsedMicroseconds ~/ count);
    say('mechanism', source.moveMechanism?.name ?? 'none');
  });
}
