import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/platform/posix/file_size.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/posix_sources.dart';
import '../../support/fs/temp_tree.dart';

/// Sizes read past a stale size of the file system
/// (`docs/stage2_android.md`, 5.26): on a phone, `stat` reported 0 bytes
/// for files just written, and the undo then took them for changed.
/// Temporary folders only; [_StaleSizes] plays the phone's FUSE layer.
void main() {
  late TempTree tree;
  const session = SessionId('session-1');

  setUp(() async {
    tree = await TempTree.create();
    tree
      ..file('Download/note.txt', text: 'note 3279\n')
      ..file('Download/empty.txt', bytes: const [])
      ..file('Download/other.txt', text: 'other');
  });

  LogicalPath p(String value) => LogicalPath(value);

  Future<T> ok<T>(Future<FileResult<T>> call) async => switch (await call) {
    FileSuccess(:final value) => value,
    FileFailure(:final error) => fail('expected success, got $error'),
  };

  group('SizeReader', () {
    const sizes = SizeReader();

    test('a file reported empty is counted by reading it', () async {
      expect(await sizes.size('${tree.root}/Download/note.txt', 0), 10);
    });

    test('an empty file stays empty', () async {
      expect(await sizes.size('${tree.root}/Download/empty.txt', 0), 0);
    });

    test('any other reported size is taken as it is', () async {
      // Not read: the file holds 5 bytes.
      expect(await sizes.size('${tree.root}/Download/other.txt', 7), 7);
    });

    test('a file that cannot be read keeps the reported size', () async {
      expect(await sizes.size('${tree.root}/missing', 0), 0);
    });
  });

  group('the adapter on a file system with stale sizes', () {
    // Fresh for each test: it records what it was asked.
    _StaleSizes staleSizes() => _StaleSizes(
      (real) => real.endsWith('note.txt') || real.contains('/quarantine/'),
    );

    test('stat gives the real size', () async {
      final stale = staleSizes();
      final fs = await openPosix(tree.root, sizes: stale);
      expect((await ok(fs.stat(p('Download/note.txt')))).size, 10);
      expect((await ok(fs.stat(p('Download/empty.txt')))).size, 0);
      expect(stale.asked, contains(endsWith('/Download/note.txt')));
    });

    test('the listing gives the real size', () async {
      final stale = staleSizes();
      final fs = await openPosix(tree.root, sizes: stale);
      final sizes = {
        for (final page in await fs.list().toList())
          for (final entry in (page as FileSuccess<FileListPage>).value.entries)
            entry.path.value: entry.size,
      };
      expect(sizes, {
        'Download/empty.txt': 0,
        'Download/note.txt': 10,
        'Download/other.txt': 5,
      });
      expect(stale.asked, contains(endsWith('/Download/note.txt')));
    });

    test('the size does not change when it stops being stale', () async {
      // What made the undo refuse: a fingerprint taken while the size was
      // stale no longer matched once the cache was dropped.
      final staleFs = await openPosix(tree.root, sizes: staleSizes());
      final whileStale = await ok(staleFs.stat(p('Download/note.txt')));
      final freshFs = await openPosix(tree.root);
      final later = await ok(freshFs.stat(p('Download/note.txt')));
      expect(whileStale, later);
    });

    test('a quarantined file is found while its size is stale', () async {
      final stale = staleSizes();
      final fs = await openPosix(tree.root, sizes: stale);
      final ref = await ok(fs.quarantine(p('Download/note.txt'), session));
      stale.asked.clear();
      expect(
        await ok(fs.findQuarantined(session, p('Download/note.txt'))),
        ref,
      );
      expect(stale.asked, [endsWith('/quarantine/session-1/1')]);
      final fresh = await openPosix(tree.root);
      expect(
        await ok(fresh.findQuarantined(session, p('Download/note.txt'))),
        ref,
      );
    });
  });
}

/// Like the phone's FUSE layer: reports 0 bytes for the paths [isStale]
/// accepts, whatever they hold.
final class _StaleSizes extends SizeReader {
  _StaleSizes(this.isStale);

  final bool Function(String real) isStale;

  /// Every path a size was asked for.
  final List<String> asked = [];

  @override
  Future<int> size(String real, int reported) {
    asked.add(real);
    return super.size(real, isStale(real) ? 0 : reported);
  }
}
