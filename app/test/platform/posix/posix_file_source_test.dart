import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/platform/posix/posix_file_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/temp_tree.dart';

/// Behavior of the POSIX adapter beyond the `FileSource` contract
/// (`docs/stage2_android.md`, section 5.5): order and cursor on a real
/// tree, links, special files, folders without access, names that are not
/// UTF-8. Runs on temporary folders of the host only.
void main() {
  late TempTree tree;

  setUp(() async => tree = await TempTree.create());

  // One item per page by default: a page keeps files and inaccessible
  // folders apart, so only single-item pages show their order.
  PosixFileSource source({int pageSize = 1}) {
    final fs = PosixFileSource(
      sourceId: const SourceId('posix'),
      root: tree.root,
      pageSize: pageSize,
    );
    addTearDown(fs.dispose);
    return fs;
  }

  LogicalPath p(String value) => LogicalPath(value);

  FileListPage okPage(FileResult<FileListPage> result) => switch (result) {
    FileSuccess(:final value) => value,
    FileFailure(:final error) => fail('list failed: $error'),
  };

  Future<List<FileListPage>> pages(
    PosixFileSource fs, {
    ScanCursor? after,
    bool Function(LogicalPath)? skipFolder,
  }) async => [
    for (final page
        in await fs.list(after: after, skipFolder: skipFolder).toList())
      okPage(page),
  ];

  /// Every item in listing order: file paths, and inaccessible folders
  /// marked with a trailing ` (inaccessible)`.
  Future<List<String>> items(
    PosixFileSource fs, {
    ScanCursor? after,
    bool Function(LogicalPath)? skipFolder,
  }) async => [
    for (final page in await pages(fs, after: after, skipFolder: skipFolder))
      ..._pageItems(page),
  ];

  Future<FileErrorKind?> statError(PosixFileSource fs, String path) async =>
      (await fs.stat(p(path))).errorKind;

  group('order and cursor', () {
    // Names whose order differs between whole paths and segments:
    // ' ' (0x20), '-' (0x2d) and '.' (0x2e) sort before '/' (0x2f).
    void givenTrickyNames() => tree
      ..file('a b/x')
      ..file('a-b/x')
      ..file('a.b')
      ..file('a/x')
      ..file('a/y/z')
      ..file('Z.txt')
      ..file('б.txt')
      ..file('😀.txt')
      ..file('я/в/ж.txt');

    const expectedOrder = [
      'Z.txt',
      'a/x',
      'a/y/z',
      'a b/x',
      'a-b/x',
      'a.b',
      'б.txt',
      'я/в/ж.txt',
      '😀.txt',
    ];

    test('is depth first by segment, names by code units', () async {
      givenTrickyNames();
      expect(await items(source()), expectedOrder);
    });

    test('pages hold at most pageSize items; the cursor is the last '
        'path', () async {
      givenTrickyNames();
      final listed = await pages(source(pageSize: 4));
      expect(listed.every((page) => page.inaccessible.isEmpty), isTrue);
      expect([for (final page in listed) page.entries.length], [4, 4, 1]);
      expect(listed.first.cursor, const ScanCursor('a b/x'));
      expect(listed.last.cursor, const ScanCursor('😀.txt'));
    });

    for (final pageSize in [1, 2, 3]) {
      test('resumes after every page (page size $pageSize)', () async {
        givenTrickyNames();
        final fs = source(pageSize: pageSize);
        final listed = await pages(fs);
        final seen = <String>[];
        for (final page in listed) {
          seen.addAll(_pageItems(page));
          expect(
            await items(fs, after: page.cursor),
            expectedOrder.sublist(seen.length),
            reason: 'after ${page.cursor}',
          );
        }
        expect(seen, expectedOrder);
      });
    }

    test('resumes after a cursor whose file is gone', () async {
      givenTrickyNames();
      final fs = source();
      tree.remove('a/y');
      expect(await items(fs, after: const ScanCursor('a/y/z')), [
        'a b/x',
        'a-b/x',
        'a.b',
        'б.txt',
        'я/в/ж.txt',
        '😀.txt',
      ]);
    });

    test('resumes after a cursor at an inaccessible folder', () async {
      tree
        ..file('a.txt')
        ..file('dir/b.txt')
        ..link('link', 'dir')
        ..file('z.txt');
      final fs = source();
      expect(await items(fs), [
        'a.txt',
        'dir/b.txt',
        'link (inaccessible)',
        'z.txt',
      ]);
      expect(await items(fs, after: const ScanCursor('link')), ['z.txt']);
    });

    test('resumes inside a folder that became readable', () async {
      tree
        ..file('dir/b.txt')
        ..file('z.txt');
      await tree.lock('dir');
      final fs = source();
      expect(await items(fs), ['dir (inaccessible)', 'z.txt']);

      await tree.unlock('dir');
      expect(await items(fs, after: const ScanCursor('dir')), [
        'dir/b.txt',
        'z.txt',
      ]);
    });

    test('does not enter skipped folders, before or after a cursor', () async {
      givenTrickyNames();
      final fs = source();
      bool skip(LogicalPath folder) =>
          folder.value == 'a' || folder.value == 'я';
      expect(await items(fs, skipFolder: skip), [
        'Z.txt',
        'a b/x',
        'a-b/x',
        'a.b',
        'б.txt',
        '😀.txt',
      ]);
      expect(
        await items(fs, after: const ScanCursor('a/x'), skipFolder: skip),
        ['a b/x', 'a-b/x', 'a.b', 'б.txt', '😀.txt'],
      );
    });

    test('an empty source has no pages', () async {
      expect(await pages(source()), isEmpty);
    });

    test('a cursor that is not a logical path fails', () async {
      tree.file('a.txt');
      final results = await source()
          .list(after: const ScanCursor('/etc'))
          .toList();
      expect(results.single.errorKind, FileErrorKind.ioError);
    });

    test('reports modification times in UTC with microseconds', () async {
      final time = DateTime.utc(2024, 5, 6, 7, 8, 9, 10, 11);
      tree.file('a.txt', modifiedAt: time.toLocal());
      final entry = (await pages(source())).single.entries.single;
      expect(entry.modifiedAt, time);
      expect(entry.modifiedAt.isUtc, isTrue);
      final stat = await source().stat(p('a.txt'));
      expect((stat as FileSuccess<FileStat>).value.modifiedAt, time);
    });
  });

  group('root', () {
    test('a missing root ends the listing with notFound', () async {
      final fs = PosixFileSource(
        sourceId: const SourceId('posix'),
        root: '${tree.root}/missing',
      );
      addTearDown(fs.dispose);
      final results = await fs.list().toList();
      expect(results.single.errorKind, FileErrorKind.notFound);
      expect(
        (await fs.stat(LogicalPath.root)).errorKind,
        FileErrorKind.notFound,
      );
      expect(await fs.exists(LogicalPath.root), const FileSuccess(false));
    });

    test('a root without access ends the listing', () async {
      tree.dir('locked');
      await tree.lock('locked');
      final fs = PosixFileSource(
        sourceId: const SourceId('posix'),
        root: '${tree.root}/locked',
      );
      addTearDown(fs.dispose);
      final results = await fs.list().toList();
      expect(results.single.errorKind, FileErrorKind.permissionDenied);
    });

    test('a root that is a file ends the listing with wrongType', () async {
      tree.file('file');
      final fs = PosixFileSource(
        sourceId: const SourceId('posix'),
        root: '${tree.root}/file',
      );
      addTearDown(fs.dispose);
      expect(
        (await fs.list().toList()).single.errorKind,
        FileErrorKind.wrongType,
      );
    });

    test('the root may be a link; it is the source', () async {
      tree
        ..file('real/dir/a.txt')
        ..link('root-link', 'real');
      final fs = PosixFileSource(
        sourceId: const SourceId('posix'),
        root: '${tree.root}/root-link/',
      );
      addTearDown(fs.dispose);
      expect(await items(fs), ['dir/a.txt']);
      expect((await fs.stat(p('dir/a.txt'))).isSuccess, isTrue);
      expect((await fs.stat(LogicalPath.root)).isSuccess, isTrue);
    });

    test('must be absolute', () {
      expect(
        () => PosixFileSource(sourceId: const SourceId('x'), root: 'rel'),
        throwsArgumentError,
      );
    });
  });

  group('links', () {
    setUp(() {
      tree
        ..file('a.txt')
        ..file('dir/b.txt')
        ..link('file-link', 'a.txt')
        ..link('dir-link', 'dir')
        ..link('broken', 'nowhere')
        ..dir('outside-target')
        ..file('outside-target/c.txt')
        ..link('dir/out', '../outside-target');
    });

    test('a link to a file is skipped, a link to a folder is '
        'inaccessible', () async {
      expect(await items(source()), [
        'a.txt',
        'dir/b.txt',
        'dir/out (inaccessible)',
        'dir-link (inaccessible)',
        'outside-target/c.txt',
      ]);
    });

    test('stat says wrongType for links; exists says the name is '
        'taken', () async {
      final fs = source();
      for (final link in ['file-link', 'dir-link', 'broken']) {
        expect(
          await statError(fs, link),
          FileErrorKind.wrongType,
          reason: link,
        );
        expect(await fs.exists(p(link)), const FileSuccess(true), reason: link);
      }
    });

    test('paths behind a link to a folder are not part of the '
        'source', () async {
      final fs = source();
      for (final path in ['dir-link/b.txt', 'dir/out/c.txt', 'dir-link/x']) {
        expect(
          await statError(fs, path),
          FileErrorKind.wrongType,
          reason: path,
        );
        expect(
          (await fs.exists(p(path))).errorKind,
          FileErrorKind.wrongType,
          reason: path,
        );
        expect(
          (await fs.fullHash(p(path))).errorKind,
          FileErrorKind.wrongType,
          reason: path,
        );
      }
      // The same files through their real paths.
      expect((await fs.stat(p('dir/b.txt'))).isSuccess, isTrue);
      expect((await fs.stat(p('outside-target/c.txt'))).isSuccess, isTrue);
    });
  });

  group('special files', () {
    test('FIFOs and sockets are not listed and are wrongType', () async {
      tree.file('a.txt');
      await tree.fifo('pipe');
      await tree.socket('sock');
      final fs = source();
      expect(await items(fs), ['a.txt']);
      for (final name in ['pipe', 'sock']) {
        expect(
          await statError(fs, name),
          FileErrorKind.wrongType,
          reason: name,
        );
        expect(await fs.exists(p(name)), const FileSuccess(true), reason: name);
        expect(
          (await fs.fullHash(p(name))).errorKind,
          FileErrorKind.wrongType,
          reason: name,
        );
      }
    });
  });

  group('folders without access', () {
    setUp(() async {
      tree
        ..file('a.txt')
        ..file('locked/inner/b.txt')
        ..file('z.txt');
      await tree.lock('locked');
    });

    test('are reported inaccessible; the rest is listed', () async {
      final fs = source();
      expect(await items(fs), ['a.txt', 'locked (inaccessible)', 'z.txt']);
    });

    test('are skipped without a report when excluded', () async {
      final fs = source();
      expect(await items(fs, skipFolder: (f) => f.value == 'locked'), [
        'a.txt',
        'z.txt',
      ]);
    });

    test('paths inside are permissionDenied, the folder itself is '
        'described', () async {
      final fs = source();
      expect(
        (await fs.stat(p('locked'))).isSuccess,
        isTrue,
        reason: 'the parent can be read',
      );
      for (final path in ['locked/inner', 'locked/inner/b.txt', 'locked/x']) {
        expect(
          await statError(fs, path),
          FileErrorKind.permissionDenied,
          reason: path,
        );
        expect(
          (await fs.exists(p(path))).errorKind,
          FileErrorKind.permissionDenied,
          reason: path,
        );
      }
    });
  });

  group('names that are not UTF-8', () {
    test('make their folder inaccessible; other files are listed', () async {
      tree
        ..file('a.txt')
        ..file('mixed/ok.txt')
        ..rawNamedFile('mixed', const [0x66, 0xff, 0x2e, 0x74]) // f\xff.t
        ..file('z.txt');
      expect(await items(source()), [
        'a.txt',
        'mixed (inaccessible)',
        'mixed/ok.txt',
        'z.txt',
      ]);
    });

    test('a valid name with U+FFFD is an ordinary file', () async {
      tree.file('mixed/�.txt');
      expect(await items(source()), ['mixed/�.txt']);
    });

    test('in the root, the root is reported and resuming does not repeat '
        'it', () async {
      tree
        ..file('a.txt')
        ..rawNamedFile('', const [0xc3, 0x28]);
      final fs = source();
      final listed = await pages(fs);
      expect(
        [for (final page in listed) ..._pageItems(page)],
        [' (inaccessible)', 'a.txt'],
      );
      expect(await items(fs, after: listed.first.cursor), ['a.txt']);
    });
  });

  group('stat and exists', () {
    test('a path under a file does not exist', () async {
      tree.file('a.txt');
      final fs = source();
      expect(await statError(fs, 'a.txt/x'), FileErrorKind.notFound);
      expect(await statError(fs, 'a.txt/x/y'), FileErrorKind.notFound);
      expect(await fs.exists(p('a.txt/x')), const FileSuccess(false));
      expect(await fs.exists(p('a.txt/x/y')), const FileSuccess(false));
      expect(await fs.exists(p('missing/x/y')), const FileSuccess(false));
    });

    test('folders have size 0', () async {
      tree.file('dir/a.txt', text: 'hello');
      final stat = await source().stat(p('dir'));
      expect(stat, isA<FileSuccess<FileStat>>());
      final value = (stat as FileSuccess<FileStat>).value;
      expect((value.kind, value.size), (FileKind.directory, 0));
    });
  });

  group('part I', () {
    test('reads only: capabilities off, changes unsupported', () async {
      tree.file('a.txt');
      final fs = source();
      expect(fs.capabilities, SourceCapabilities.none);
      expect(fs.appFolders, {p('.FileOrganizer')});
      const session = SessionId('s');
      final ref = QuarantineRef('s/1');
      final calls = <Future<FileResult<Object?>>>[
        fs.mkdir(p('new')),
        fs.move(p('a.txt'), p('b.txt')),
        fs.quarantine(p('a.txt'), session),
        fs.findQuarantined(session, p('a.txt')),
        fs.restore(ref, p('b.txt')),
        fs.removeEmptyDir(p('a.txt')),
        fs.purgeQuarantined(ref),
        fs.addToAlbum(p('a.txt')),
        fs.removeFromAlbum(p('a.txt')),
      ];
      for (final call in calls) {
        expect((await call).errorKind, FileErrorKind.unsupported);
      }
      expect(await items(fs), ['a.txt']);
    });
  });
}

/// Items of [page]: inaccessible folders marked with ` (inaccessible)`, then
/// files. In walk order only if the page has a single item or no folders.
List<String> _pageItems(FileListPage page) => [
  for (final folder in page.inaccessible) '${folder.value} (inaccessible)',
  for (final entry in page.entries) entry.path.value,
];
