import 'package:file_organizer/core/dedupe/dedupe.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/core/scan/scan.dart';
import 'package:file_organizer/core/zones/zones.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/repositories/in_memory_repositories.dart';
import '../../support/scenarios.dart';
import '../../support/sequential_id_generator.dart';

void main() {
  late InMemoryFileIndexRepository index;
  late DuplicateFinder finder;

  setUp(() {
    index = InMemoryFileIndexRepository();
    finder = DuplicateFinder(index: index);
  });

  /// Scans [fs] into the index and builds its zones, as the pipeline does.
  Future<ZoneMap> scanned(InMemoryFileSource fs) async {
    final zones = ZoneMap(sourceId: fs.sourceId);
    await Scanner(
      index: index,
      checkpoints: InMemoryScanCheckpointRepository(),
      ids: SequentialIdGenerator('scan'),
    ).scan(fs, skipFolder: zones.skipFolder).drain<void>();
    return ZoneMap(
      sourceId: fs.sourceId,
      files: await index.bySource(fs.sourceId),
    );
  }

  Future<DedupeCompleted> find(InMemoryFileSource fs, [ZoneMap? zones]) async {
    final events = await finder.find(fs, zones ?? await scanned(fs)).toList();
    return events.last as DedupeCompleted;
  }

  List<List<String>> pathsOf(DedupeCompleted result) => [
    for (final group in result.groups)
      [for (final file in group.files) file.path.value],
  ];

  List<String> hashCalls(InMemoryFileSource fs, FsMethod method) => [
    for (final call in fs.calls)
      if (call.method == method) call.path!.value,
  ];

  group('typical Download folder', () {
    late InMemoryFileSource fs;
    late DedupeCompleted result;

    setUp(() async {
      fs = InMemoryFileSource()..withTypicalDownloadFolder();
      result = await find(fs);
    });

    test('finds the invoice and its "(1)" copy', () {
      expect(pathsOf(result), [
        ['Download/invoice_2024 (1).pdf', 'Download/invoice_2024.pdf'],
      ]);
      final group = result.groups.single;
      expect(group.keeper.path.value, 'Download/invoice_2024.pdf');
      expect(group.keeperReason, KeeperReason.earliestModified);
      expect(group.extras.single.path.value, 'Download/invoice_2024 (1).pdf');
    });

    test('tells the same-size decoy apart only by the full hash', () {
      const a = 'Download/holiday.mp4';
      const b = 'Download/holiday-edit.mp4';
      expect(hashCalls(fs, FsMethod.partialHash), containsAll([a, b]));
      expect(hashCalls(fs, FsMethod.fullHash), containsAll([a, b]));
      expect(pathsOf(result).expand((g) => g), isNot(contains(a)));
    });

    test('never touches files of a unique size', () {
      final sizes = <int, List<String>>{};
      for (final MapEntry(:key, :value) in fs.snapshot().files.entries) {
        (sizes[value.size] ??= []).add(key);
      }
      final unique = [
        for (final paths in sizes.values)
          if (paths.length == 1) paths.single,
      ];
      expect(unique, isNotEmpty);
      final touched = fs.calls
          .where((c) => c.method != FsMethod.list)
          .map((c) => c.path!.value)
          .toSet();
      expect(touched.intersection(unique.toSet()), isEmpty);
    });

    test('ignores empty files', () {
      expect(
        fs.calls.where((c) => c.path?.value == 'Download/empty.txt'),
        isEmpty,
      );
    });

    test('only reads', () {
      expect(fs.mutations, isEmpty);
    });

    test('caches the hashes in the index', () async {
      final invoice = await index.byPath(
        fs.sourceId,
        LogicalPath('Download/invoice_2024.pdf'),
      );
      expect(invoice!.fullHash, result.groups.single.fullHash);
      final video = await index.byPath(
        fs.sourceId,
        LogicalPath('Download/holiday.mp4'),
      );
      expect(video!.partialHash, isNotNull);
      expect(video.fullHash, isNotNull);
    });

    test('a second run reads nothing and finds the same', () async {
      fs.calls.clear();
      final again = await find(
        fs,
        ZoneMap(
          sourceId: fs.sourceId,
          files: await index.bySource(fs.sourceId),
        ),
      );
      expect(fs.calls, isEmpty);
      expect(again.groups, result.groups);
      expect(again.filesHashed, 0);
    });
  });

  group('cascade', () {
    test('files of different sizes are never hashed', () async {
      final fs = InMemoryFileSource()
        ..addFile('a.txt', text: 'one')
        ..addFile('b.txt', text: 'three');
      final result = await find(fs);
      expect(result.groups, isEmpty);
      expect(fs.calls.where((c) => c.method != FsMethod.list), isEmpty);
    });

    test('small files go straight to the full hash', () async {
      final fs = InMemoryFileSource()
        ..addFile('a.txt', text: 'same')
        ..addFile('b.txt', text: 'same')
        ..addFile('c.txt', text: 'diff');
      final result = await find(fs);
      expect(hashCalls(fs, FsMethod.partialHash), isEmpty);
      expect(hashCalls(fs, FsMethod.fullHash), ['a.txt', 'b.txt', 'c.txt']);
      expect(pathsOf(result), [
        ['a.txt', 'b.txt'],
      ]);
    });

    test(
      'large files with different partial hashes skip the full hash',
      () async {
        final fs = InMemoryFileSource()
          ..addFile('a.bin', bytes: largeContent(seed: 1, size: 300000))
          ..addFile('b.bin', bytes: largeContent(seed: 2, size: 300000));
        final result = await find(fs);
        expect(hashCalls(fs, FsMethod.partialHash), ['a.bin', 'b.bin']);
        expect(hashCalls(fs, FsMethod.fullHash), isEmpty);
        expect(result.groups, isEmpty);
      },
    );

    test('large identical files go through all steps', () async {
      final content = largeContent(seed: 5, size: 300000);
      final fs = InMemoryFileSource()
        ..addFile('a.bin', bytes: content)
        ..addFile('b.bin', bytes: content)
        ..addFile(
          'c.bin',
          bytes: largeContent(seed: 5, size: 300000, middleSeed: 9),
        );
      final result = await find(fs);
      expect(hashCalls(fs, FsMethod.fullHash), ['a.bin', 'b.bin', 'c.bin']);
      expect(pathsOf(result), [
        ['a.bin', 'b.bin'],
      ]);
    });

    test('empty files are never duplicates', () async {
      final fs = InMemoryFileSource()
        ..addFile('a.txt', bytes: const [])
        ..addFile('b.txt', bytes: const [])
        ..addFile('Documents/c.txt', bytes: const []);
      final result = await find(fs);
      expect(result.groups, isEmpty);
      expect(fs.calls.where((c) => c.method != FsMethod.list), isEmpty);
    });

    test('several groups of the same size stay apart', () async {
      final fs = InMemoryFileSource()
        ..addFile('a1', text: 'aaaa')
        ..addFile('b1', text: 'bbbb')
        ..addFile('a2', text: 'aaaa')
        ..addFile('b2', text: 'bbbb')
        ..addFile('a3', text: 'aaaa');
      expect(pathsOf(await find(fs)), [
        ['a1', 'a2', 'a3'],
        ['b1', 'b2'],
      ]);
    });
  });

  group('zones', () {
    test('excluded files take no part', () async {
      final fs = InMemoryFileSource()
        ..addFile('Download/a.txt', text: 'same')
        ..addFile('Download/project/pubspec.yaml')
        ..addFile('Download/project/a.txt', text: 'same')
        ..addFile('Download/notes.part', text: 'same');
      final result = await find(fs);
      expect(result.groups, isEmpty);
      expect(fs.calls.where((c) => c.method == FsMethod.fullHash), isEmpty);
    });

    test('a copy in an organized folder is kept', () async {
      final fs = InMemoryFileSource()
        ..addFile(
          'Download/scan.pdf',
          text: 'same',
          modifiedAt: DateTime.utc(2020),
        )
        ..addFile(
          'Documents/scan.pdf',
          text: 'same',
          modifiedAt: DateTime.utc(2024),
        );
      final group = (await find(fs)).groups.single;
      expect(group.keeper.path.value, 'Documents/scan.pdf');
      expect(group.keeperReason, KeeperReason.organizedLocation);
    });

    test(
      'groups with every copy in organized folders are reported too',
      () async {
        final fs = InMemoryFileSource()
          ..addFile('Documents/a.pdf', text: 'same')
          ..addFile('Archive/a.pdf', text: 'same');
        expect(pathsOf(await find(fs)), [
          ['Archive/a.pdf', 'Documents/a.pdf'],
        ]);
      },
    );

    test('the zones must belong to the source', () {
      final fs = InMemoryFileSource();
      expect(
        () => finder.find(fs, ZoneMap(sourceId: const SourceId('other'))),
        throwsArgumentError,
      );
    });
  });

  test('phone: every received copy keeps the camera original', () async {
    final result = await find(phoneStorage());
    expect(result.groups, hasLength(3));
    for (final group in result.groups) {
      expect(group.keeper.path.value, startsWith('DCIM/Camera/'));
      expect(group.keeperReason, KeeperReason.organizedLocation);
      expect(group.extras, hasLength(1));
    }
  });

  test('duplicates are looked for within one source only', () async {
    final a = InMemoryFileSource(sourceId: const SourceId('a'))
      ..addFile('x.txt', text: 'same');
    final b = InMemoryFileSource(sourceId: const SourceId('b'))
      ..addFile('x.txt', text: 'same')
      ..addFile('y.txt', text: 'other');
    await scanned(a);
    expect((await find(b)).groups, isEmpty);
    expect((await find(a)).groups, isEmpty);
  });

  group('files that cannot be hashed', () {
    test('are skipped and reported; the rest goes on', () async {
      final fs = InMemoryFileSource()
        ..addFile('a.txt', text: 'same')
        ..addFile('b.txt', text: 'same')
        ..addFile('c.txt', text: 'same')
        ..addFile('d.txt', text: 'same');
      final zones = await scanned(fs);
      fs
        ..lock('b.txt')
        ..removeExternally('c.txt');

      final result = await find(fs, zones);

      expect(pathsOf(result), [
        ['a.txt', 'd.txt'],
      ]);
      expect(result.skipped, [
        DedupeSkip(LogicalPath('b.txt'), const FileError(FileErrorKind.locked)),
        DedupeSkip(
          LogicalPath('c.txt'),
          const FileError(FileErrorKind.notFound),
        ),
      ]);
    });

    test('a group left with one file is no group', () async {
      final fs = InMemoryFileSource()
        ..addFile('a.txt', text: 'same')
        ..addFile('b.txt', text: 'same');
      final zones = await scanned(fs);
      fs.failOn(FileErrorKind.ioError, methods: {FsMethod.fullHash});
      final result = await find(fs, zones);
      expect(result.groups, isEmpty);
      expect(result.skipped, hasLength(1));
    });
  });

  group('progress and cancellation', () {
    late InMemoryFileSource fs;
    setUp(() {
      fs = InMemoryFileSource()
        ..addFile('a1', text: 'a')
        ..addFile('a2', text: 'a')
        ..addFile('b1', text: 'bb')
        ..addFile('b2', text: 'bb')
        ..addFile('c1', text: 'ccc')
        ..addFile('c2', text: 'ccc');
    });

    test('reports each size bucket', () async {
      final events = await finder.find(fs, await scanned(fs)).toList();
      expect(events.whereType<DedupeProgress>().toList(), [
        DedupeProgress(
          fs.sourceId,
          sizesDone: 1,
          sizesTotal: 3,
          filesHashed: 2,
        ),
        DedupeProgress(
          fs.sourceId,
          sizesDone: 2,
          sizesTotal: 3,
          filesHashed: 4,
        ),
        DedupeProgress(
          fs.sourceId,
          sizesDone: 3,
          sizesTotal: 3,
          filesHashed: 6,
        ),
      ]);
      expect((events.last as DedupeCompleted).filesHashed, 6);
    });

    test('cancelling keeps the hashes computed so far', () async {
      final zones = await scanned(fs);
      await finder.find(fs, zones).take(1).drain<void>();
      final cached = [
        for (final e in await index.bySource(fs.sourceId))
          if (e.fullHash != null) e.path.value,
      ];
      expect(cached, ['a1', 'a2']);

      fs.calls.clear();
      final result = await find(fs, zones);
      expect(hashCalls(fs, FsMethod.fullHash), ['b1', 'b2', 'c1', 'c2']);
      expect(result.groups, hasLength(3));
    });
  });

  test('the result is deterministic', () async {
    Future<DedupeCompleted> fresh() async {
      index = InMemoryFileIndexRepository();
      finder = DuplicateFinder(index: index);
      return find(phoneStorage()..withTypicalDownloadFolder(root: 'Desktop'));
    }

    final first = await fresh();
    final second = await fresh();
    expect(second, first);
    expect(
      first.groups.map((g) => g.keeper.path),
      orderedEquals(first.groups.map((g) => g.keeper.path).toList()..sort()),
    );
  });
}
