import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/core/scan/scan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/repositories/in_memory_repositories.dart';
import '../../support/scenarios.dart';
import '../../support/sequential_id_generator.dart';

void main() {
  late InMemoryFileSource fs;
  late InMemoryFileIndexRepository index;
  late InMemoryScanCheckpointRepository checkpoints;
  late Scanner scanner;
  late int fileCount;

  setUp(() {
    fs = InMemoryFileSource(pageSize: 4)..withTypicalDownloadFolder();
    fileCount = fs.snapshot().files.length;
    index = InMemoryFileIndexRepository();
    checkpoints = InMemoryScanCheckpointRepository();
    scanner = Scanner(
      index: index,
      checkpoints: checkpoints,
      ids: SequentialIdGenerator('scan'),
    );
  });

  Future<List<ScanEvent>> scan({
    InMemoryFileSource? source,
    bool Function(LogicalPath)? skipFolder,
  }) => scanner.scan(source ?? fs, skipFolder: skipFolder).toList();

  ScanSummary summaryOf(List<ScanEvent> events) =>
      (events.last as ScanCompleted).summary;

  Future<Map<String, FileEntry>> indexed([SourceId? sourceId]) async => {
    for (final entry in await index.bySource(sourceId ?? fs.sourceId))
      entry.path.value: entry,
  };

  Future<void> giveHashes(String path) async {
    final entry = (await index.byPath(fs.sourceId, LogicalPath(path)))!;
    await index.upsertAll([
      FileEntry(
        sourceId: entry.sourceId,
        path: entry.path,
        size: entry.size,
        modifiedAt: entry.modifiedAt,
        capturedAt: entry.capturedAt,
        mimeType: entry.mimeType,
        partialHash: 'partial-$path',
        fullHash: 'full-$path',
        lastSeenScanId: entry.lastSeenScanId,
      ),
    ]);
  }

  bool isHashCall(FsCall call) =>
      call.method == FsMethod.partialHash || call.method == FsMethod.fullHash;

  group('first scan', () {
    test('indexes every file with its metadata and no hashes', () async {
      final summary = summaryOf(await scan());

      final entries = await indexed();
      expect(entries.keys.toSet(), fs.snapshot().files.keys.toSet());
      final invoice = entries['Download/invoice_2024.pdf']!;
      expect(invoice.size, fs.readBytes('Download/invoice_2024.pdf').length);
      expect(invoice.modifiedAt, DateTime.utc(2024, 1, 15, 12));
      expect(entries.values.map((e) => e.lastSeenScanId).toSet(), {
        const ScanId('scan-1'),
      });
      expect(entries.values.map((e) => e.fullHash), everyElement(isNull));
      expect(entries.values.map((e) => e.partialHash), everyElement(isNull));

      expect(
        summary,
        ScanSummary(
          sourceId: fs.sourceId,
          scanId: const ScanId('scan-1'),
          resumed: false,
          added: fileCount,
          updated: 0,
          unchanged: 0,
          removed: 0,
          inaccessible: const [],
        ),
      );
    });

    test('reports progress after every page', () async {
      final events = await scan();
      final progress = events.whereType<ScanProgress>().toList();
      expect(progress.map((e) => e.filesProcessed), [
        for (var n = 4; n < fileCount + 4; n += 4)
          n < fileCount ? n : fileCount,
      ]);
      expect(progress.map((e) => e.sourceId).toSet(), {fs.sourceId});
      expect(events.last, isA<ScanCompleted>());
    });

    test('only reads: no changes, no hashing', () async {
      final before = fs.snapshot();
      await scan();
      expect(fs.snapshot(), before);
      expect(fs.mutations, isEmpty);
      expect(fs.calls.where(isHashCall), isEmpty);
    });

    test('leaves no checkpoint behind', () async {
      await scan();
      expect(await checkpoints.bySource(fs.sourceId), isNull);
    });

    test('indexes capture dates when the source provides them', () async {
      final phone = phoneStorage();
      await scan(source: phone);
      final photo = (await indexed(
        phone.sourceId,
      ))['DCIM/Camera/IMG_20240203_093000.jpg']!;
      expect(photo.capturedAt, DateTime.utc(2024, 2, 3, 9, 30));
    });
  });

  group('repeated scan', () {
    test('keeps the hashes of unchanged files', () async {
      await scan();
      await giveHashes('Download/invoice_2024.pdf');
      await giveHashes('Download/holiday.mp4');
      fs.calls.clear();

      final summary = summaryOf(await scan());

      expect(summary.unchanged, fileCount);
      expect(summary.added + summary.updated + summary.removed, 0);
      expect(summary.scanId, const ScanId('scan-2'));
      final invoice = (await indexed())['Download/invoice_2024.pdf']!;
      expect(invoice.partialHash, 'partial-Download/invoice_2024.pdf');
      expect(invoice.fullHash, 'full-Download/invoice_2024.pdf');
      expect(invoice.lastSeenScanId, const ScanId('scan-2'));
      expect((await indexed())['Download/holiday.mp4']!.fullHash, isNotNull);
      expect(fs.calls.where(isHashCall), isEmpty);
    });

    test('updates a file with new content and drops its hashes', () async {
      await scan();
      await giveHashes('Download/notes.txt');
      fs.writeFile(
        'Download/notes.txt',
        text: 'a longer text than before',
        modifiedAt: DateTime.utc(2024, 9, 2),
      );

      final summary = summaryOf(await scan());

      expect(summary.updated, 1);
      expect(summary.unchanged, fileCount - 1);
      final notes = (await indexed())['Download/notes.txt']!;
      expect(notes.size, 'a longer text than before'.length);
      expect(notes.modifiedAt, DateTime.utc(2024, 9, 2));
      expect(notes.partialHash, isNull);
      expect(notes.fullHash, isNull);
    });

    test('a new modification time alone counts as a change', () async {
      await scan();
      await giveHashes('Download/notes.txt');
      fs.writeFile('Download/notes.txt', modifiedAt: DateTime.utc(2025));

      expect(summaryOf(await scan()).updated, 1);
      expect((await indexed())['Download/notes.txt']!.fullHash, isNull);
    });

    test('a new size alone counts as a change', () async {
      await scan();
      await giveHashes('Download/notes.txt');
      final mtime = (await indexed())['Download/notes.txt']!.modifiedAt;
      fs.writeFile('Download/notes.txt', text: 'x', modifiedAt: mtime);

      expect(summaryOf(await scan()).updated, 1);
      expect((await indexed())['Download/notes.txt']!.fullHash, isNull);
    });

    test('same size and time count as unchanged, by design', () async {
      // The scan compares size and modification time only (spec 4.1). A
      // content change that keeps both is caught later by the fingerprint
      // check with the full hash before any operation.
      await scan();
      await giveHashes('Download/notes.txt');
      final before = fs.readText('Download/notes.txt');
      final mtime = (await indexed())['Download/notes.txt']!.modifiedAt;
      fs.writeFile(
        'Download/notes.txt',
        text: 'X' * before.length,
        modifiedAt: mtime,
      );

      expect(summaryOf(await scan()).unchanged, fileCount);
    });

    test('adds new files and removes vanished ones', () async {
      await scan();
      fs
        ..addFile('Download/new.pdf')
        ..removeExternally('Download/notes.txt')
        ..removeExternally('Download/project');

      final summary = summaryOf(await scan());

      expect(summary.added, 1);
      expect(summary.removed, 3);
      final entries = await indexed();
      expect(entries, contains('Download/new.pdf'));
      expect(entries, isNot(contains('Download/notes.txt')));
      expect(entries.keys.where((p) => p.contains('project/')), isEmpty);
      expect(entries.keys.toSet(), fs.snapshot().files.keys.toSet());
    });
  });

  group('excluded folders', () {
    bool skipExcluded(LogicalPath folder) =>
        folder.name.startsWith('.') || folder.name == 'node_modules';

    test('are not entered and not indexed', () async {
      await scan(skipFolder: skipExcluded);
      final entries = await indexed();
      expect(entries, isNot(contains('Download/.cache/thumbs.db')));
      expect(
        entries,
        isNot(contains('Download/project/node_modules/left-pad/index.js')),
      );
      expect(entries, contains('Download/project/main.dart'));
      expect(entries, hasLength(fileCount - 2));
    });

    test('leave the index when a folder becomes excluded', () async {
      await scan();
      final summary = summaryOf(await scan(skipFolder: skipExcluded));
      expect(summary.removed, 2);
      expect(await indexed(), hasLength(fileCount - 2));
    });
  });

  test('reports inaccessible folders and does not index them', () async {
    fs
      ..addFile('Private/a.txt')
      ..denyAccess('Private');
    final summary = summaryOf(await scan());
    expect(summary.inaccessible, [LogicalPath('Private')]);
    expect(await indexed(), isNot(contains('Private/a.txt')));
  });

  group('interruption and resume', () {
    Future<Map<String, FileEntry>> uninterrupted() async {
      final freshIndex = InMemoryFileIndexRepository();
      await Scanner(
        index: freshIndex,
        checkpoints: InMemoryScanCheckpointRepository(),
        ids: SequentialIdGenerator('scan'),
      ).scan(fs).drain<void>();
      return {
        for (final e in await freshIndex.bySource(fs.sourceId)) e.path.value: e,
      };
    }

    test('a crash keeps the position of the last indexed page', () async {
      fs.crashOn(methods: {FsMethod.list}, nth: 3);
      await expectLater(scan(), throwsA(isA<SimulatedCrash>()));

      final checkpoint = (await checkpoints.bySource(fs.sourceId))!;
      expect(checkpoint.scanId, const ScanId('scan-1'));
      expect(checkpoint.stage, ScanStage.listing);
      final indexedSoFar = await indexed();
      expect(indexedSoFar, hasLength(8));
      expect(checkpoint.cursor, ScanCursor(indexedSoFar.keys.last));
    });

    test('the next scan resumes after that page and completes', () async {
      final expected = await uninterrupted();
      fs.crashOn(methods: {FsMethod.list}, nth: 3);
      await expectLater(scan(), throwsA(isA<SimulatedCrash>()));
      fs
        ..clearFaults()
        ..calls.clear();

      final summary = summaryOf(await scan());

      expect(summary.resumed, isTrue);
      expect(summary.scanId, const ScanId('scan-1'), reason: 'same scan');
      expect(summary.added, fileCount - 8);
      final firstListed = fs.calls.firstWhere((c) => c.method == FsMethod.list);
      final cursor = (await index.bySource(fs.sourceId))[7].path;
      expect(firstListed.path!.compareTo(cursor), greaterThan(0));
      expect(await indexed(), expected);
      expect(await checkpoints.bySource(fs.sourceId), isNull);
    });

    test('cancelling stops after a page and the scan resumes later', () async {
      final expected = await uninterrupted();
      final first = await scanner.scan(fs).take(2).toList();
      expect(first.whereType<ScanCompleted>(), isEmpty);
      expect(await indexed(), hasLength(8));
      expect((await checkpoints.bySource(fs.sourceId))!.cursor, isNotNull);

      final summary = summaryOf(await scan());
      expect(summary.resumed, isTrue);
      expect(await indexed(), expected);
    });

    test('a listing failure ends the scan and removes nothing', () async {
      await scan();
      fs
        ..removeExternally('Download/notes.txt')
        ..failOn(FileErrorKind.ioError, methods: {FsMethod.list}, nth: 2);

      final events = await scan();

      expect(events, [
        ScanProgress(fs.sourceId, filesProcessed: 4),
        ScanFailed(
          fs.sourceId,
          error: const FileError(FileErrorKind.ioError, 'injected'),
          filesProcessed: 4,
        ),
      ]);
      expect(
        await indexed(),
        contains('Download/notes.txt'),
        reason: 'an incomplete scan must not drop entries',
      );
      expect(await checkpoints.bySource(fs.sourceId), isNotNull);

      final retry = summaryOf(await scan());
      expect(retry.resumed, isTrue);
      expect(retry.removed, 1);
      expect(await indexed(), isNot(contains('Download/notes.txt')));
    });

    test('a crash while finalizing resumes without listing again', () async {
      await scan();
      await checkpoints.save(
        ScanCheckpoint(
          sourceId: fs.sourceId,
          scanId: const ScanId('scan-1'),
          stage: ScanStage.finalizing,
          cursor: const ScanCursor('Download/table.xlsx'),
        ),
      );
      await index.upsertAll([
        FileEntry(
          sourceId: fs.sourceId,
          path: LogicalPath('Download/stale.pdf'),
          size: 1,
          modifiedAt: DateTime.utc(2020),
          lastSeenScanId: const ScanId('scan-0'),
        ),
      ]);
      fs.calls.clear();

      final summary = summaryOf(await scan());

      expect(fs.calls, isEmpty);
      expect(summary.resumed, isTrue);
      expect(summary.removed, 1);
      expect(summary.filesSeen, 0);
      expect(await indexed(), hasLength(fileCount));
      expect(await checkpoints.bySource(fs.sourceId), isNull);
    });
  });

  test('sources do not affect each other', () async {
    final other = InMemoryFileSource(sourceId: const SourceId('other'))
      ..addFile('Download/notes.txt');
    await scan();
    await scan(source: other);
    other.removeExternally('Download/notes.txt');
    await scan(source: other);

    expect(await indexed(), hasLength(fileCount));
    expect(await indexed(other.sourceId), isEmpty);
  });
}
