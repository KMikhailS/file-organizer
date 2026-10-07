import 'dart:convert';
import 'dart:io';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/platform/posix/move_probe.dart';
import 'package:file_organizer/platform/posix/no_replace_mover.dart';
import 'package:file_organizer/platform/posix/posix_file_source.dart';
import 'package:file_organizer/platform/posix/posix_paths.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/fs/posix_sources.dart';
import '../../support/fs/temp_tree.dart';

/// Changing files with the POSIX adapter beyond the `FileSource` contract
/// (`docs/stage2_android.md`, section 5.7): the probe, the adapter's own
/// folder, links, and the layout of the quarantine. Temporary folders only.
void main() {
  late TempTree tree;
  const session = SessionId('session-1');

  setUp(() async {
    tree = await TempTree.create();
    tree
      ..file('a.txt', text: 'a')
      ..file('dir/b.txt', text: 'bb')
      ..dir('empty');
  });

  LogicalPath p(String value) => LogicalPath(value);

  Future<T> ok<T>(Future<FileResult<T>> call) async => switch (await call) {
    FileSuccess(:final value) => value,
    FileFailure(:final error) => fail('expected success, got $error'),
  };

  Future<FileErrorKind?> error(Future<FileResult<Object?>> call) async =>
      (await call).errorKind;

  String text(String path) => utf8.decode(tree.bytesOf(path)!);

  group('probe', () {
    test('picks renameat2 on Linux and leaves only its own files', () async {
      final fs = await openPosix(tree.root);
      expect(fs.moveMechanism, MoveMechanism.renameNoReplace);
      expect(fs.probeProblem, isNull);
      expect(fs.capabilities.canMove, isTrue);
      expect(fs.capabilities.canMkdir, isTrue);
      expect(fs.capabilities.canQuarantine, isTrue);
      expect(fs.capabilities.quarantineRestorable, isTrue);
      expect(fs.capabilities.providesCapturedAt, isFalse);
      expect(fs.capabilities.systemPurgesQuarantine, isFalse);
      expect(tree.namesIn('.FileOrganizer'), ['.nomedia', 'probe']);
      expect(tree.namesIn('.FileOrganizer/probe'), ['a', 'b']);
      expect(tree.namesIn(''), ['.FileOrganizer', 'a.txt', 'dir', 'empty']);
    });

    test('the fallback works when forced', () async {
      final fs = await openPosix(
        tree.root,
        mechanism: MoveMechanism.reserveThenRename,
      );
      expect(fs.moveMechanism, MoveMechanism.reserveThenRename);
      expect(tree.namesIn('.FileOrganizer/probe'), ['a', 'b']);
    });

    test('opening again and again does not pile up files', () async {
      for (var i = 0; i < 5; i++) {
        await openPosix(tree.root);
        await openPosix(tree.root, mechanism: MoveMechanism.reserveThenRename);
      }
      expect(tree.namesIn('.FileOrganizer/probe'), ['a', 'b']);
      expect(tree.namesIn('.FileOrganizer'), ['.nomedia', 'probe']);
    });

    test('repairs what an interrupted probe left', () async {
      await openPosix(tree.root);
      tree
        ..remove('.FileOrganizer/probe/a')
        ..file('.FileOrganizer/probe/c0', bytes: const []);
      final fs = await openPosix(tree.root);
      expect(fs.moveMechanism, MoveMechanism.renameNoReplace);
      expect(tree.namesIn('.FileOrganizer/probe'), ['a', 'b', 'c0']);
    });

    test('a read-only source can be read but not changed', () async {
      await tree.makeReadOnly('');
      final fs = await openPosix(tree.root);
      expect(fs.moveMechanism, isNull);
      expect(fs.probeProblem, contains('.FileOrganizer'));
      expect(fs.capabilities, SourceCapabilities.none);
      expect(
        (await fs.list().toList()).expand(
          (r) => switch (r) {
            FileSuccess(:final value) => value.entries,
            FileFailure() => const <FileEntry>[],
          },
        ),
        hasLength(2),
      );
      expect((await fs.fullHash(p('a.txt'))).isSuccess, isTrue);
      final ref = QuarantineRef('session-1/1');
      for (final call in <Future<FileResult<Object?>>>[
        fs.mkdir(p('new')),
        fs.move(p('a.txt'), p('b.txt')),
        fs.quarantine(p('a.txt'), session),
        fs.findQuarantined(session, p('a.txt')),
        fs.restore(ref, p('b.txt')),
        fs.removeEmptyDir(p('empty')),
        fs.purgeQuarantined(ref),
        fs.addToAlbum(p('a.txt')),
        fs.removeFromAlbum(p('a.txt')),
      ]) {
        expect(await error(call), FileErrorKind.unsupported);
      }
    });

    for (final (what, make) in <(String, void Function(TempTree))>[
      ('a file', (t) => t.file('.FileOrganizer', text: 'user file')),
      ('a link to a folder', (t) => t.link('.FileOrganizer', 'dir')),
    ]) {
      test('a .FileOrganizer that is $what makes the source '
          'read-only', () async {
        make(tree);
        final fs = await openPosix(tree.root);
        expect(fs.moveMechanism, isNull);
        expect(tree.namesIn('dir'), ['b.txt']);
      });
    }

    group('on other file systems', () {
      ProbeResult probe(int Function(String from, String to) rename) =>
          probeMoves(
            paths: PosixPaths(tree.root),
            mover: (mechanism) => NoReplaceMover(
              mechanism: mechanism,
              setAsideFolder: tree.real('.FileOrganizer/placeholders'),
              uniqueSuffix: () => 'x',
            ),
            renameNoReplace: rename,
          );

      test('the flag rejected only for free names (API 30 and 34): the '
          'fallback', () {
        // As on the emulators: EEXIST for a taken name, EINVAL otherwise.
        final result = probe(
          (_, to) => File(to).existsSync() ? 17 /* EEXIST */ : 22 /* EINVAL */,
        );
        expect(result.mechanism, MoveMechanism.reserveThenRename);
        expect(tree.namesIn('.FileOrganizer/probe'), ['a', 'b']);
      });

      for (final errno in [22, 38, 95]) {
        test('the flag rejected everywhere (errno $errno): the fallback', () {
          expect(
            probe((_, _) => errno).mechanism,
            MoveMechanism.reserveThenRename,
          );
        });
      }

      test('the flag ignored: no moves at all', () {
        final result = probe((from, to) {
          File(from).renameSync(to);
          return 0;
        });
        expect(result.mechanism, isNull);
        expect(result.problem, contains('replaced'));
      });

      test('any other failure: no moves', () {
        final result = probe((_, _) => 13 /* EACCES */);
        expect(result.mechanism, isNull);
        expect(result.problem, contains('13'));
      });
    });

    test('a missing root has no capabilities', () async {
      final fs = await openPosix('${tree.root}/missing');
      expect(fs.capabilities, SourceCapabilities.none);
      expect(Directory('${tree.root}/missing').existsSync(), isFalse);
    });
  });

  group('the own folder cannot be changed through the port', () {
    late PosixFileSource fs;

    setUp(() async => fs = await openPosix(tree.root));

    test('in any case of its name', () async {
      for (final name in ['.FileOrganizer', '.fileorganizer']) {
        expect(
          await error(fs.move(p('a.txt'), p('$name/a.txt'))),
          FileErrorKind.permissionDenied,
        );
        expect(
          await error(fs.mkdir(p('$name/x'))),
          FileErrorKind.permissionDenied,
        );
      }
      expect(
        await error(fs.move(p('.FileOrganizer/.nomedia'), p('x'))),
        FileErrorKind.permissionDenied,
      );
      expect(
        await error(fs.quarantine(p('.FileOrganizer/.nomedia'), session)),
        FileErrorKind.permissionDenied,
      );
      expect(
        await error(fs.removeEmptyDir(p('.FileOrganizer/probe'))),
        FileErrorKind.permissionDenied,
      );
      final ref = await ok(fs.quarantine(p('a.txt'), session));
      expect(
        await error(fs.restore(ref, p('.FileOrganizer/a.txt'))),
        FileErrorKind.permissionDenied,
      );
      expect(text('.FileOrganizer/.nomedia'), isEmpty);
      expect(tree.namesIn('.FileOrganizer/probe'), ['a', 'b']);
    });

    test('the root is neither created nor removed', () async {
      expect(
        await error(fs.mkdir(LogicalPath.root)),
        FileErrorKind.targetExists,
      );
      expect(
        await error(fs.removeEmptyDir(LogicalPath.root)),
        FileErrorKind.unsupported,
      );
    });
  });

  group('links are never followed', () {
    late PosixFileSource fs;

    setUp(() async {
      tree
        ..dir('outside/inner')
        ..link('file-link', 'a.txt')
        ..link('dir-link', 'dir')
        ..link('empty-link', 'empty')
        ..link('dir/out', '../outside');
      fs = await openPosix(tree.root);
    });

    test('a link is not moved, quarantined or removed', () async {
      expect(
        await error(fs.move(p('file-link'), p('moved'))),
        FileErrorKind.wrongType,
      );
      expect(
        await error(fs.quarantine(p('file-link'), session)),
        FileErrorKind.wrongType,
      );
      expect(
        await error(fs.removeEmptyDir(p('empty-link'))),
        FileErrorKind.wrongType,
      );
      expect(Link(tree.real('file-link')).existsSync(), isTrue);
      expect(Link(tree.real('empty-link')).existsSync(), isTrue);
      expect(Directory(tree.real('empty')).existsSync(), isTrue);
    });

    test('nothing goes into or comes out of a linked folder', () async {
      expect(
        await error(fs.move(p('a.txt'), p('dir-link/a.txt'))),
        FileErrorKind.wrongType,
      );
      expect(
        await error(fs.move(p('dir-link/b.txt'), p('b.txt'))),
        FileErrorKind.wrongType,
      );
      expect(await error(fs.mkdir(p('dir/out/new'))), FileErrorKind.wrongType);
      expect(
        await error(fs.removeEmptyDir(p('dir/out/inner'))),
        FileErrorKind.wrongType,
      );
      expect(tree.namesIn('dir'), ['b.txt', 'out']);
      expect(tree.namesIn('outside'), ['inner']);
      expect(text('a.txt'), 'a');
    });
  });

  group('mkdir and removeEmptyDir', () {
    late PosixFileSource fs;

    setUp(() async => fs = await openPosix(tree.root));

    test('mkdir under a file is notFound', () async {
      expect(await error(fs.mkdir(p('a.txt/x'))), FileErrorKind.notFound);
    });

    test('a folder with only a hidden file is not empty', () async {
      tree.file('empty/.hidden', bytes: const []);
      expect(
        await error(fs.removeEmptyDir(p('empty'))),
        FileErrorKind.notEmpty,
      );
      expect(tree.namesIn('empty'), ['.hidden']);
    });
  });

  group('quarantine', () {
    late PosixFileSource fs;
    late FakeClock clock;

    setUp(() async {
      clock = FakeClock(start: DateTime.utc(2024, 7, 8, 9));
      fs = await openPosix(tree.root, clock: clock);
    });

    Map<String, Object?> description(String path) =>
        jsonDecode(text(path)) as Map<String, Object?>;

    test('keeps the file and its description in the session '
        'folder', () async {
      File(tree.real('dir/b.txt'))
          .setLastModifiedSync(DateTime.utc(2023, 1, 2, 3, 4, 5));
      final ref = await ok(fs.quarantine(p('dir/b.txt'), session));
      expect(ref, QuarantineRef('session-1/1'));
      expect(tree.namesIn('.FileOrganizer/quarantine/session-1'), [
        '1',
        '1.json',
      ]);
      expect(text('.FileOrganizer/quarantine/session-1/1'), 'bb');
      expect(description('.FileOrganizer/quarantine/session-1/1.json'), {
        'original': 'dir/b.txt',
        'size': 2,
        'modifiedAt': '2023-01-02T03:04:05.000Z',
        'quarantinedAt': '2024-07-08T09:00:00.000Z',
      });
      expect(tree.namesIn('.FileOrganizer'), [
        '.nomedia',
        'probe',
        'quarantine',
      ]);
    });

    test('numbers go on after files and descriptions already '
        'there', () async {
      tree
        ..file('.FileOrganizer/quarantine/session-1/4', text: 'orphan')
        ..file('.FileOrganizer/quarantine/session-1/6.json', bytes: const []);
      final ref = await ok(fs.quarantine(p('a.txt'), session));
      expect(ref, QuarantineRef('session-1/7'));
    });

    test('an orphaned file is never found but can be purged', () async {
      tree.file('.FileOrganizer/quarantine/session-1/4', text: 'orphan');
      final ref = await ok(fs.quarantine(p('a.txt'), session));
      expect(await ok(fs.findQuarantined(session, p('a.txt'))), ref);
      await ok(fs.purgeQuarantined(QuarantineRef('session-1/4')));
      expect(tree.namesIn('.FileOrganizer/quarantine/session-1'), [
        '5',
        '5.json',
      ]);
    });

    test('a description without its file is not found', () async {
      final ref = await ok(fs.quarantine(p('a.txt'), session));
      // As if the move into the quarantine never happened.
      tree.remove('.FileOrganizer/quarantine/session-1/1');
      expect(await ok(fs.findQuarantined(session, p('a.txt'))), isNull);
      expect(await error(fs.restore(ref, p('a.txt'))), FileErrorKind.notFound);
    });

    test('a file that changed in the quarantine is not found', () async {
      await ok(fs.quarantine(p('a.txt'), session));
      tree.file('.FileOrganizer/quarantine/session-1/1', text: 'longer');
      expect(await ok(fs.findQuarantined(session, p('a.txt'))), isNull);
    });

    test('purge removes the session folder with its last file', () async {
      final r1 = await ok(fs.quarantine(p('a.txt'), session));
      final r2 = await ok(fs.quarantine(p('dir/b.txt'), session));
      await ok(fs.purgeQuarantined(r1));
      expect(tree.namesIn('.FileOrganizer/quarantine/session-1'), [
        '2',
        '2.json',
      ]);
      await ok(fs.purgeQuarantined(r2));
      expect(tree.namesIn('.FileOrganizer/quarantine'), isEmpty);
    });

    test('purge and restore accept only references of the '
        'quarantine', () async {
      await ok(fs.quarantine(p('dir/b.txt'), session));
      for (final value in [
        'a.txt',
        '../a.txt',
        'session-1/../../../a.txt',
        'session-1/1/../../../../a.txt',
        '../../a.txt/1',
        'session-1/01',
        'session-1/1.json',
        '.hidden/1',
        'session-1/1/x',
        '/session-1/1',
      ]) {
        final ref = QuarantineRef(value);
        expect(
          await error(fs.purgeQuarantined(ref)),
          FileErrorKind.notFound,
          reason: value,
        );
        expect(
          await error(fs.restore(ref, p('x.txt'))),
          FileErrorKind.notFound,
          reason: value,
        );
      }
      expect(text('a.txt'), 'a');
      expect(text('.FileOrganizer/quarantine/session-1/1'), 'bb');
      expect(tree.namesIn('.FileOrganizer/quarantine/session-1'), [
        '1',
        '1.json',
      ]);
    });

    test('a session id that cannot be a folder name is refused', () async {
      for (final id in ['../x', '.hidden', 'a/b', '', '..']) {
        expect(
          await error(fs.quarantine(p('a.txt'), SessionId(id))),
          FileErrorKind.ioError,
          reason: id,
        );
        expect(await ok(fs.findQuarantined(SessionId(id), p('a.txt'))), isNull);
      }
      expect(text('a.txt'), 'a');
    });

    test('works with the fallback mechanism too', () async {
      final fallback = await openPosix(
        tree.root,
        mechanism: MoveMechanism.reserveThenRename,
      );
      final ref = await ok(fallback.quarantine(p('a.txt'), session));
      expect(await ok(fallback.findQuarantined(session, p('a.txt'))), ref);
      await ok(fallback.restore(ref, p('a.txt')));
      expect(text('a.txt'), 'a');
    });
  });
}
