import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import 'in_memory_file_source.dart';

void main() {
  const session = SessionId('s1');
  LogicalPath p(String value) => LogicalPath(value);

  late InMemoryFileSource fs;
  setUp(() {
    fs = InMemoryFileSource()
      ..addFile('a.txt', text: 'A')
      ..addFile('b.txt', text: 'B')
      ..addFile('c.txt', text: 'C')
      ..addDir('Documents');
  });

  Future<List<FileListPage>> pages(
    InMemoryFileSource source, {
    ScanCursor? after,
  }) async => [
    for (final result in await source.list(after: after).toList())
      (result as FileSuccess<FileListPage>).value,
  ];

  group('setup', () {
    test('creates parent folders and default content', () {
      fs.addFile('x/y/z.txt');
      expect(fs.isDirectory('x'), isTrue);
      expect(fs.isDirectory('x/y'), isTrue);
      expect(fs.readText('x/y/z.txt'), 'x/y/z.txt');
    });

    test('refuses to replace anything', () {
      expect(() => fs.addFile('a.txt'), throwsStateError);
      expect(() => fs.addFile('a.txt/x'), throwsStateError);
    });

    test('external edits and deletions bypass the port', () async {
      final before = await fs.fullHash(p('a.txt'));
      fs.writeFile('a.txt', text: 'edited', modifiedAt: DateTime.utc(2030));
      expect(await fs.fullHash(p('a.txt')), isNot(before));
      expect(
        (await fs.stat(p('a.txt')) as FileSuccess<FileStat>).value.modifiedAt,
        DateTime.utc(2030),
      );

      fs
        ..addFile('Documents/inner/x.txt')
        ..removeExternally('Documents');
      expect(fs.isDirectory('Documents'), isFalse);
      expect(fs.isFile('Documents/inner/x.txt'), isFalse);
      expect(fs.calls.where((c) => c.method.isMutating), isEmpty);
    });
  });

  group('failOn', () {
    test('fails the nth mutating call without any effect', () async {
      fs.failOn(FileErrorKind.ioError, nth: 2);
      final before = fs.snapshot();

      expect((await fs.mkdir(p('one'))).isSuccess, isTrue);
      final afterFirst = fs.snapshot();
      final second = await fs.move(p('a.txt'), p('Documents/a.txt'));
      expect(second.errorKind, FileErrorKind.ioError);
      expect(
        fs.snapshot(),
        afterFirst,
        reason: 'a failed call changes nothing',
      );
      expect(
        (await fs.move(p('a.txt'), p('Documents/a.txt'))).isSuccess,
        isTrue,
      );
      expect(before.diff(fs.snapshot()), hasLength(3));
    });

    test('counts only calls that match the method and path', () async {
      fs.failOn(FileErrorKind.locked, methods: {FsMethod.move}, path: 'b.txt');
      await fs.mkdir(p('x'));
      expect((await fs.move(p('a.txt'), p('x/a.txt'))).isSuccess, isTrue);
      expect(
        (await fs.move(p('b.txt'), p('x/b.txt'))).errorKind,
        FileErrorKind.locked,
      );
      expect((await fs.move(p('b.txt'), p('x/b.txt'))).isSuccess, isTrue);
    });

    test('matches the target path too', () async {
      fs.failOn(FileErrorKind.permissionDenied, path: 'Documents/a.txt');
      expect(
        (await fs.move(p('a.txt'), p('Documents/a.txt'))).errorKind,
        FileErrorKind.permissionDenied,
      );
    });

    test('fails several calls in a row with times', () async {
      fs.failOn(FileErrorKind.ioError, methods: {FsMethod.fullHash}, times: 2);
      expect((await fs.fullHash(p('a.txt'))).errorKind, FileErrorKind.ioError);
      expect((await fs.fullHash(p('a.txt'))).errorKind, FileErrorKind.ioError);
      expect((await fs.fullHash(p('a.txt'))).isSuccess, isTrue);
    });

    test('clearFaults removes the rules', () async {
      fs
        ..failOn(FileErrorKind.ioError)
        ..clearFaults();
      expect((await fs.mkdir(p('x'))).isSuccess, isTrue);
    });
  });

  group('crashOn', () {
    test('before the effect: nothing happens', () async {
      fs.crashOn(methods: {FsMethod.move});
      final before = fs.snapshot();
      await expectLater(
        fs.move(p('a.txt'), p('Documents/a.txt')),
        throwsA(
          isA<SimulatedCrash>().having(
            (c) => c.point,
            'point',
            CrashPoint.beforeEffect,
          ),
        ),
      );
      expect(fs.snapshot(), before);
    });

    test('after the effect: the change is made, the result is lost', () async {
      fs.crashOn(methods: {FsMethod.move}, point: CrashPoint.afterEffect);
      await expectLater(
        fs.move(p('a.txt'), p('Documents/a.txt')),
        throwsA(isA<SimulatedCrash>()),
      );
      expect(fs.isFile('a.txt'), isFalse);
      expect(fs.readText('Documents/a.txt'), 'A');
    });

    test('only the nth matching call crashes', () async {
      fs.crashOn(nth: 2);
      await fs.mkdir(p('x'));
      await expectLater(fs.mkdir(p('y')), throwsA(isA<SimulatedCrash>()));
      expect((await fs.mkdir(p('z'))).isSuccess, isTrue);
    });

    test('is an Error, so it cannot be mistaken for a result', () {
      expect(
        SimulatedCrash(const FsCall(FsMethod.mkdir), CrashPoint.afterEffect),
        isA<Error>(),
      );
    });
  });

  group('list', () {
    test('pages, cursors and resuming after an interrupted listing', () async {
      final small = InMemoryFileSource(pageSize: 2);
      for (final name in ['e', 'd', 'c', 'b', 'a']) {
        small.addFile('$name.txt');
      }
      final all = await pages(small);
      expect(all.map((pg) => pg.entries.map((e) => e.name)), [
        ['a.txt', 'b.txt'],
        ['c.txt', 'd.txt'],
        ['e.txt'],
      ]);

      small.crashOn(methods: {FsMethod.list}, nth: 2);
      final seen = <FileListPage>[];
      await expectLater(
        small.list().forEach(
          (r) => seen.add((r as FileSuccess<FileListPage>).value),
        ),
        throwsA(isA<SimulatedCrash>()),
      );
      expect(seen, [all.first]);

      small.clearFaults();
      expect(await pages(small, after: seen.last.cursor), all.skip(1));
    });

    test('a failing page ends the stream', () async {
      final small = InMemoryFileSource(pageSize: 1)
        ..addFile('a')
        ..addFile('b')
        ..failOn(FileErrorKind.ioError, methods: {FsMethod.list}, nth: 2);
      final results = await small.list().toList();
      expect(results.map((r) => r.errorKind), [null, FileErrorKind.ioError]);
    });

    test('reports inaccessible folders instead of their files', () async {
      fs
        ..addFile('Private/secret.txt')
        ..addFile('Private/deeper/more.txt')
        ..denyAccess('Private');
      final all = await pages(fs);
      expect(all.expand((pg) => pg.entries).map((e) => e.path.value), [
        'a.txt',
        'b.txt',
        'c.txt',
      ]);
      expect(all.expand((pg) => pg.inaccessible), [p('Private')]);
    });

    test('does not report inaccessible folders inside skipped ones', () async {
      fs
        ..addFile('node_modules/locked/x.js')
        ..denyAccess('node_modules/locked');
      final results = await fs
          .list(skipFolder: (f) => f.name == 'node_modules')
          .toList();
      final page = (results.single as FileSuccess<FileListPage>).value;
      expect(page.inaccessible, isEmpty);
    });

    test('fails when the whole source is inaccessible', () async {
      fs.denyAccess('');
      final results = await fs.list().toList();
      expect(results.single.errorKind, FileErrorKind.permissionDenied);
    });

    test('gives capture dates only with the capability', () async {
      final photos = InMemoryFileSource(
        capabilities: androidMediaStoreCapabilities,
      )..addFile('IMG.jpg', capturedAt: DateTime.utc(2020));
      final plain = InMemoryFileSource()
        ..addFile('IMG.jpg', capturedAt: DateTime.utc(2020));
      expect(
        (await pages(photos)).single.entries.single.capturedAt,
        DateTime.utc(2020),
      );
      expect((await pages(plain)).single.entries.single.capturedAt, isNull);
    });
  });

  group('lock and denyAccess', () {
    test('a locked file cannot be read, moved or quarantined', () async {
      fs.lock('a.txt');
      expect((await fs.fullHash(p('a.txt'))).errorKind, FileErrorKind.locked);
      expect(
        (await fs.move(p('a.txt'), p('Documents/a.txt'))).errorKind,
        FileErrorKind.locked,
      );
      expect(
        (await fs.quarantine(p('a.txt'), session)).errorKind,
        FileErrorKind.locked,
      );
      expect((await fs.stat(p('a.txt'))).isSuccess, isTrue);

      fs.unlock('a.txt');
      expect((await fs.fullHash(p('a.txt'))).isSuccess, isTrue);
    });

    test('denied access covers the folder and everything inside', () async {
      fs
        ..addFile('Documents/x.txt')
        ..denyAccess('Documents');
      expect(
        (await fs.stat(p('Documents/x.txt'))).errorKind,
        FileErrorKind.permissionDenied,
      );
      expect(
        (await fs.move(p('a.txt'), p('Documents/a.txt'))).errorKind,
        FileErrorKind.permissionDenied,
      );
      expect(
        (await fs.mkdir(p('Documents/new'))).errorKind,
        FileErrorKind.permissionDenied,
      );
      expect(fs.isFile('a.txt'), isTrue);

      fs.allowAccess('Documents');
      expect((await fs.stat(p('Documents/x.txt'))).isSuccess, isTrue);
    });
  });

  group('capabilities', () {
    test('iOS Photos: no moves, folders or quarantine; albums work', () async {
      final photos = InMemoryFileSource(capabilities: iosPhotosCapabilities)
        ..addFile('IMG_1.HEIC');
      final img = p('IMG_1.HEIC');

      expect(
        (await photos.move(img, p('x.HEIC'))).errorKind,
        FileErrorKind.unsupported,
      );
      expect((await photos.mkdir(p('x'))).errorKind, FileErrorKind.unsupported);
      expect(
        (await photos.quarantine(img, session)).errorKind,
        FileErrorKind.unsupported,
      );

      expect((await photos.addToAlbum(img)).isSuccess, isTrue);
      expect(photos.album, {img});
      expect(
        (await photos.addToAlbum(img)).errorKind,
        FileErrorKind.targetExists,
      );
      expect((await photos.removeFromAlbum(img)).isSuccess, isTrue);
      expect(photos.album, isEmpty);
      expect(photos.isFile('IMG_1.HEIC'), isTrue, reason: 'never deleted');
      expect(
        (await photos.removeFromAlbum(img)).errorKind,
        FileErrorKind.notFound,
      );
    });

    test(
      'quarantine without restore (system trash we cannot read back)',
      () async {
        final trash = InMemoryFileSource(
          capabilities: const SourceCapabilities(canQuarantine: true),
        )..addFile('a.txt');
        final ref = (await trash.quarantine(
          p('a.txt'),
          session,
        ) as FileSuccess<QuarantineRef>).value;
        expect(
          (await trash.restore(ref, p('a.txt'))).errorKind,
          FileErrorKind.unsupported,
        );
        expect(trash.quarantined.keys, [ref.value]);
      },
    );
  });

  group('hashing in blocks with a cancel token', () {
    const block = InMemoryFileSource.hashBlockSize;

    test(
      'full hash reads every block, partial only the first and last',
      () async {
        fs.addFile('big', bytes: List.filled(block * 3 + 1, 7));
        final blocks = <String>[];
        fs.onHashBlock = (path, n) => blocks.add('$path#$n');
        await fs.fullHash(p('big'));
        expect(blocks, ['big#0', 'big#1', 'big#2', 'big#3']);
        blocks.clear();
        await fs.partialHash(p('big'));
        expect(blocks, ['big#0', 'big#3']);
      },
    );

    test(
      'cancelling in the middle of a file stops before the next block',
      () async {
        fs.addFile('big', bytes: List.filled(block * 3, 7));
        final token = CancelToken();
        final read = <int>[];
        fs.onHashBlock = (_, n) {
          read.add(n);
          if (n == 0) {
            token.cancel();
          }
        };
        final result = await fs.fullHash(p('big'), cancel: token);
        expect(result, isA<FileFailure<String>>());
        expect(
          (result as FileFailure<String>).error.kind,
          FileErrorKind.cancelled,
        );
        expect(read, [0]);
      },
    );

    test('an empty file is one block', () async {
      fs.addFile('empty', bytes: const []);
      var blocks = 0;
      fs.onHashBlock = (_, _) => blocks++;
      await fs.fullHash(p('empty'));
      expect(blocks, 1);
    });
  });

  group('case-insensitive storage', () {
    late InMemoryFileSource ci;
    setUp(
      () => ci = InMemoryFileSource(caseSensitive: false)
        ..addFile('Photo.JPG', text: 'original')
        ..addDir('Photos'),
    );

    test('paths differing in case are the same file', () async {
      expect(() => ci.addFile('photo.jpg'), throwsStateError);
      expect(
        (await ci.exists(p('PHOTO.jpg'))) as FileSuccess<bool>,
        const FileSuccess(true),
      );
      expect(ci.readText('photo.jpg'), 'original');
    });

    test('never overwrites a file whose name differs only in case', () async {
      ci.addFile('Photos/photo.jpg', text: 'other');
      expect(
        (await ci.move(p('Photo.JPG'), p('Photos/PHOTO.jpg'))).errorKind,
        FileErrorKind.targetExists,
      );
      expect(ci.readText('Photo.JPG'), 'original');
      expect(ci.readText('Photos/photo.jpg'), 'other');
    });

    test('folders match regardless of case', () async {
      expect(
        (await ci.move(p('Photo.JPG'), p('PHOTOS/a.jpg'))).isSuccess,
        isTrue,
      );
      expect(ci.readText('Photos/a.jpg'), 'original');
    });

    test('the case-sensitive default keeps them apart', () async {
      final cs = InMemoryFileSource()..addFile('Photo.JPG');
      cs.addFile('photo.jpg');
      expect(cs.isFile('Photo.JPG') && cs.isFile('photo.jpg'), isTrue);
    });
  });

  group('snapshot', () {
    test('equal when nothing changed, with readable differences', () async {
      final before = fs.snapshot();
      expect(fs.snapshot(), before);
      expect(before.diff(fs.snapshot()), isEmpty);

      await fs.move(p('a.txt'), p('Documents/a.txt'));
      final after = fs.snapshot();
      expect(after, isNot(before));
      expect(before.diff(after), [
        startsWith('+ file Documents/a.txt'),
        startsWith('- file a.txt'),
      ]);
    });

    test('move there and back restores an equal snapshot', () async {
      final before = fs.snapshot();
      await fs.move(p('a.txt'), p('Documents/a.txt'));
      await fs.move(p('Documents/a.txt'), p('a.txt'));
      expect(fs.snapshot(), before);
    });

    test('tracks quarantine, and the tree view ignores it', () async {
      final before = fs.snapshot();
      final ref = (await fs.quarantine(
        p('b.txt'),
        session,
      ) as FileSuccess<QuarantineRef>).value;
      final during = fs.snapshot();
      expect(during.quarantined.keys, [ref.value]);
      expect(during.tree.files.keys, isNot(contains('b.txt')));

      await fs.restore(ref, p('b.txt'));
      expect(fs.snapshot(), before);
    });

    test('notices content and time changes', () {
      final before = fs.snapshot();
      fs.writeFile('a.txt', text: 'X');
      expect(before.diff(fs.snapshot()), [startsWith('~ file a.txt')]);
      final mid = fs.snapshot();
      fs.writeFile('a.txt', modifiedAt: DateTime.utc(2031));
      expect(mid.diff(fs.snapshot()), [startsWith('~ file a.txt')]);
    });

    test('is immutable', () {
      expect(() => fs.snapshot().files.clear(), throwsUnsupportedError);
    });
  });

  test('logs every port call in order', () async {
    await fs.stat(p('a.txt'));
    await fs.mkdir(p('x'));
    await fs.move(p('a.txt'), p('x/a.txt'));
    expect(fs.calls.map((c) => c.toString()), [
      'stat a.txt',
      'mkdir x',
      'move a.txt -> x/a.txt',
    ]);
    expect(fs.mutations.map((c) => c.method), [FsMethod.mkdir, FsMethod.move]);
  });
}
