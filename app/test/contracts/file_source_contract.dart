import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arranges files for the contract without going through the port, the way
/// the user or another app would.
abstract interface class FileSourceFixture {
  /// The source under test. It must support everything except albums
  /// (desktop capabilities).
  FileSource get source;

  /// Creates a file with parent folders.
  Future<void> givenFile(
    String path, {
    required List<int> bytes,
    required DateTime modifiedAt,
  });

  /// Creates a folder with parent folders.
  Future<void> givenDir(String path);
}

/// Behavior every [FileSource] implementation must have. Checks results
/// through the port only, so it runs against real adapters as well.
void fileSourceContract(Future<FileSourceFixture> Function() create) {
  late FileSourceFixture fixture;
  late FileSource fs;
  final t1 = DateTime.utc(2024, 3, 1, 12);
  final t2 = DateTime.utc(2024, 4, 1, 12);
  const session = SessionId('session-1');

  LogicalPath p(String value) => LogicalPath(value);

  setUp(() async {
    fixture = await create();
    fs = fixture.source;
    await fixture.givenFile('a.txt', bytes: [1, 2, 3], modifiedAt: t1);
    await fixture.givenFile('dir/b.txt', bytes: [4, 5], modifiedAt: t2);
    await fixture.givenFile('dir/sub/c.txt', bytes: [6], modifiedAt: t1);
    await fixture.givenDir('empty');
  });

  Future<T> ok<T>(Future<FileResult<T>> call) async {
    final result = await call;
    return switch (result) {
      FileSuccess(:final value) => value,
      FileFailure(:final error) => fail('expected success, got $error'),
    };
  }

  Future<void> expectError(
    Future<FileResult<Object?>> call,
    FileErrorKind kind,
  ) async {
    expect((await call).errorKind, kind);
  }

  Future<bool> exists(String path) => ok(fs.exists(p(path)));

  Future<String> hashOf(String path) => ok(fs.fullHash(p(path)));

  FileListPage okPage(FileResult<FileListPage> result) => switch (result) {
    FileSuccess(:final value) => value,
    FileFailure(:final error) => fail('list failed: $error'),
  };

  Future<List<FileEntry>> listAll({
    ScanCursor? after,
    bool Function(LogicalPath)? skipFolder,
  }) async {
    final entries = <FileEntry>[];
    await for (final page in fs.list(after: after, skipFolder: skipFolder)) {
      entries.addAll(okPage(page).entries);
    }
    return entries;
  }

  group('list', () {
    test('returns every file with metadata and without hashes', () async {
      final entries = await listAll();
      expect(entries.map((e) => e.path.value).toSet(), {
        'a.txt',
        'dir/b.txt',
        'dir/sub/c.txt',
      });
      final b = entries.singleWhere((e) => e.path.value == 'dir/b.txt');
      expect(b.sourceId, fs.sourceId);
      expect(b.size, 2);
      expect(b.modifiedAt, t2);
      expect(b.partialHash, isNull);
      expect(b.fullHash, isNull);
      expect(b.lastSeenScanId, isNull);
    });

    test('has a stable order', () async {
      expect(
        (await listAll()).map((e) => e.path),
        (await listAll()).map((e) => e.path),
      );
    });

    test('does not enter skipped folders', () async {
      final entries = await listAll(skipFolder: (f) => f.value == 'dir/sub');
      expect(entries.map((e) => e.path.value).toSet(), {'a.txt', 'dir/b.txt'});
    });

    test('resumes after any page without losing or repeating files', () async {
      final all = await listAll();
      final pages = (await fs.list().toList()).map(okPage);
      for (final page in pages) {
        final before = all.takeWhile((e) => !page.entries.contains(e));
        final resumed = await listAll(after: page.cursor);
        final upToPage = [...before, ...page.entries];
        expect([...upToPage, ...resumed], all, reason: 'after ${page.cursor}');
      }
    });
  });

  group('stat and exists', () {
    test('describe files and folders', () async {
      final file = await ok(fs.stat(p('a.txt')));
      expect(file.kind, FileKind.file);
      expect(file.size, 3);
      expect(file.modifiedAt, t1);
      expect((await ok(fs.stat(p('dir')))).kind, FileKind.directory);
      expect((await ok(fs.stat(LogicalPath.root))).kind, FileKind.directory);
      expect(await exists('a.txt'), isTrue);
      expect(await exists('dir'), isTrue);
      expect(await exists(''), isTrue);
    });

    test('report missing paths', () async {
      await expectError(fs.stat(p('nope.txt')), FileErrorKind.notFound);
      expect(await exists('nope.txt'), isFalse);
    });
  });

  group('hashes', () {
    test('equal content gives equal hashes', () async {
      await fixture.givenFile('copy.txt', bytes: [1, 2, 3], modifiedAt: t2);
      expect(await hashOf('copy.txt'), await hashOf('a.txt'));
      expect(
        await ok(fs.partialHash(p('copy.txt'))),
        await ok(fs.partialHash(p('a.txt'))),
      );
    });

    test('different content gives different hashes', () async {
      expect(await hashOf('dir/b.txt'), isNot(await hashOf('a.txt')));
    });

    test('partial hash covers only the size and both ends', () async {
      const size = 200 * 1024;
      final original = List<int>.generate(size, (i) => i % 251);
      final changedMiddle = List<int>.of(original)..[size ~/ 2] ^= 0xff;
      final changedEnd = List<int>.of(original)..[size - 1] ^= 0xff;
      await fixture.givenFile('big1', bytes: original, modifiedAt: t1);
      await fixture.givenFile('big2', bytes: changedMiddle, modifiedAt: t1);
      await fixture.givenFile('big3', bytes: changedEnd, modifiedAt: t1);

      final partial1 = await ok(fs.partialHash(p('big1')));
      expect(await ok(fs.partialHash(p('big2'))), partial1);
      expect(await ok(fs.partialHash(p('big3'))), isNot(partial1));
      expect(await hashOf('big2'), isNot(await hashOf('big1')));
    });

    test('fail for folders and missing files', () async {
      await expectError(fs.fullHash(p('dir')), FileErrorKind.wrongType);
      await expectError(fs.fullHash(p('nope')), FileErrorKind.notFound);
      await expectError(fs.partialHash(p('nope')), FileErrorKind.notFound);
    });
  });

  group('mkdir', () {
    test('creates one level', () async {
      await ok(fs.mkdir(p('dir/new')));
      expect((await ok(fs.stat(p('dir/new')))).kind, FileKind.directory);
    });

    test('needs the parent', () async {
      await expectError(fs.mkdir(p('x/y')), FileErrorKind.notFound);
      expect(await exists('x'), isFalse);
    });

    test('never replaces anything', () async {
      await expectError(fs.mkdir(p('dir')), FileErrorKind.targetExists);
      await expectError(fs.mkdir(p('a.txt')), FileErrorKind.targetExists);
      expect(await hashOf('a.txt'), isNotEmpty);
      await expectError(fs.mkdir(LogicalPath.root), FileErrorKind.targetExists);
    });
  });

  group('move', () {
    test('moves content and keeps the modification time', () async {
      final hash = await hashOf('a.txt');
      await ok(fs.move(p('a.txt'), p('dir/sub/moved.txt')));
      expect(await exists('a.txt'), isFalse);
      expect(await hashOf('dir/sub/moved.txt'), hash);
      expect((await ok(fs.stat(p('dir/sub/moved.txt')))).modifiedAt, t1);
    });

    test('never overwrites: both files stay intact', () async {
      final a = await hashOf('a.txt');
      final b = await hashOf('dir/b.txt');
      await expectError(
        fs.move(p('a.txt'), p('dir/b.txt')),
        FileErrorKind.targetExists,
      );
      expect(await hashOf('a.txt'), a);
      expect(await hashOf('dir/b.txt'), b);
    });

    test('does not replace a folder', () async {
      await expectError(
        fs.move(p('a.txt'), p('empty')),
        FileErrorKind.targetExists,
      );
      expect(await exists('a.txt'), isTrue);
    });

    test('needs the target folder', () async {
      await expectError(
        fs.move(p('a.txt'), p('missing/a.txt')),
        FileErrorKind.notFound,
      );
      expect(await exists('a.txt'), isTrue);
      expect(await exists('missing'), isFalse);
    });

    test('moves files only', () async {
      await expectError(fs.move(p('dir'), p('dir2')), FileErrorKind.wrongType);
      expect(await exists('dir/b.txt'), isTrue);
    });

    test('fails for a missing file', () async {
      await expectError(
        fs.move(p('nope.txt'), p('x.txt')),
        FileErrorKind.notFound,
      );
    });
  });

  group('quarantine', () {
    test('takes the file away and restores it intact', () async {
      final hash = await hashOf('dir/b.txt');
      final ref = await ok(fs.quarantine(p('dir/b.txt'), session));
      expect(await exists('dir/b.txt'), isFalse);

      await ok(fs.restore(ref, p('dir/b.txt')));
      expect(await hashOf('dir/b.txt'), hash);
      expect((await ok(fs.stat(p('dir/b.txt')))).modifiedAt, t2);
    });

    test('restores to another path', () async {
      final ref = await ok(fs.quarantine(p('a.txt'), session));
      await ok(fs.restore(ref, p('dir/a (restored).txt')));
      expect(await exists('dir/a (restored).txt'), isTrue);
    });

    test('gives distinct references', () async {
      final r1 = await ok(fs.quarantine(p('a.txt'), session));
      final r2 = await ok(fs.quarantine(p('dir/b.txt'), session));
      expect(r1, isNot(r2));
    });

    test('restore never overwrites and keeps the quarantined file', () async {
      final ref = await ok(fs.quarantine(p('a.txt'), session));
      await fixture.givenFile('a.txt', bytes: [9], modifiedAt: t2);
      final newer = await hashOf('a.txt');

      await expectError(
        fs.restore(ref, p('a.txt')),
        FileErrorKind.targetExists,
      );
      expect(await hashOf('a.txt'), newer);

      await ok(fs.restore(ref, p('a (restored).txt')));
      expect(await exists('a (restored).txt'), isTrue);
    });

    test('restore needs the target folder', () async {
      final ref = await ok(fs.quarantine(p('dir/b.txt'), session));
      await expectError(
        fs.restore(ref, p('gone/b.txt')),
        FileErrorKind.notFound,
      );
      await ok(fs.restore(ref, p('b.txt')));
    });

    test('quarantines files only', () async {
      await expectError(
        fs.quarantine(p('dir'), session),
        FileErrorKind.wrongType,
      );
      await expectError(
        fs.quarantine(p('nope'), session),
        FileErrorKind.notFound,
      );
    });

    test('finds a quarantined file by session and original path', () async {
      final ref = await ok(fs.quarantine(p('dir/b.txt'), session));
      expect(await ok(fs.findQuarantined(session, p('dir/b.txt'))), ref);
      expect(await ok(fs.findQuarantined(session, p('a.txt'))), isNull);
      expect(
        await ok(fs.findQuarantined(const SessionId('other'), p('dir/b.txt'))),
        isNull,
      );
      await ok(fs.purgeQuarantined(ref));
      expect(await ok(fs.findQuarantined(session, p('dir/b.txt'))), isNull);
    });

    test('purge is final', () async {
      final ref = await ok(fs.quarantine(p('a.txt'), session));
      await ok(fs.purgeQuarantined(ref));
      await expectError(fs.restore(ref, p('a.txt')), FileErrorKind.notFound);
      await expectError(fs.purgeQuarantined(ref), FileErrorKind.notFound);
      expect(await exists('a.txt'), isFalse);
    });
  });

  group('removeEmptyDir', () {
    test('removes an empty folder', () async {
      await ok(fs.removeEmptyDir(p('empty')));
      expect(await exists('empty'), isFalse);
    });

    test('never removes a folder with content', () async {
      await expectError(fs.removeEmptyDir(p('dir')), FileErrorKind.notEmpty);
      await expectError(
        fs.removeEmptyDir(p('dir/sub')),
        FileErrorKind.notEmpty,
      );
      expect(await exists('dir/sub/c.txt'), isTrue);
    });

    test('never removes a file', () async {
      await expectError(fs.removeEmptyDir(p('a.txt')), FileErrorKind.wrongType);
      expect(await exists('a.txt'), isTrue);
    });

    test('fails for a missing folder', () async {
      await expectError(fs.removeEmptyDir(p('nope')), FileErrorKind.notFound);
    });
  });

  test('albums are unsupported without the capability', () async {
    expect(fs.capabilities.canAddToAlbum, isFalse);
    await expectError(fs.addToAlbum(p('a.txt')), FileErrorKind.unsupported);
    await expectError(
      fs.removeFromAlbum(p('a.txt')),
      FileErrorKind.unsupported,
    );
  });
}
