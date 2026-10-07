import 'dart:io';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/platform/posix/no_replace_mover.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/temp_tree.dart';

/// Both mechanisms of decision A.5 on real temporary folders, including the
/// race window of "reserve, then rename" played by a test hook.
void main() {
  late TempTree tree;
  var suffix = 0;

  setUp(() async {
    suffix = 0;
    tree = await TempTree.create();
    tree
      ..file('src/a.txt', text: 'mine')
      ..file('dst/taken.txt', text: 'theirs')
      ..dir('aside-parent');
  });

  NoReplaceMover mover(MoveMechanism mechanism) => NoReplaceMover(
    mechanism: mechanism,
    setAsideFolder: tree.real('aside-parent/aside'),
    uniqueSuffix: () => 'p${suffix++}',
  );

  String text(String path) => String.fromCharCodes(tree.bytesOf(path)!);

  for (final mechanism in MoveMechanism.values) {
    group(mechanism.name, () {
      test('moves to a free name', () {
        final result = mover(mechanism)
            .move(tree.real('src/a.txt'), tree.real('dst/a.txt'));
        expect(result.isSuccess, isTrue);
        expect(text('dst/a.txt'), 'mine');
        expect(tree.bytesOf('src/a.txt'), isNull);
      });

      test('never replaces a taken name', () {
        final result = mover(mechanism)
            .move(tree.real('src/a.txt'), tree.real('dst/taken.txt'));
        expect(result.errorKind, FileErrorKind.targetExists);
        expect(text('dst/taken.txt'), 'theirs');
        expect(text('src/a.txt'), 'mine');
      });

      test('never replaces a folder', () {
        final result = mover(mechanism)
            .move(tree.real('src/a.txt'), tree.real('dst'));
        expect(result.errorKind, FileErrorKind.targetExists);
        expect(text('src/a.txt'), 'mine');
      });

      test('needs the target folder and the source', () {
        final m = mover(mechanism);
        expect(
          m.move(tree.real('src/a.txt'), tree.real('nope/a.txt')).errorKind,
          FileErrorKind.notFound,
        );
        expect(
          m.move(tree.real('src/nope'), tree.real('dst/x')).errorKind,
          FileErrorKind.notFound,
        );
        expect(tree.namesIn('dst'), ['taken.txt']);
        expect(text('src/a.txt'), 'mine');
      });
    });
  }

  group('reserve then rename: another app in the race window', () {
    late NoReplaceMover m;
    var calls = 0;

    setUp(() {
      calls = 0;
      m = mover(MoveMechanism.reserveThenRename);
    });

    /// Runs [action] on the placeholder of the first reservation only (the
    /// set-aside reserves names too).
    void onFirstReserve(void Function(String placeholder) action) =>
        m.afterReserve = (placeholder) {
          if (calls++ == 0) {
            action(placeholder);
          }
        };

    test('writes into the placeholder: its data is kept', () {
      onFirstReserve(
        (placeholder) => File(placeholder).writeAsStringSync('other app'),
      );
      final result = m.move(tree.real('src/a.txt'), tree.real('dst/a.txt'));
      expect(result.errorKind, FileErrorKind.targetExists);
      expect(text('dst/a.txt'), 'other app');
      expect(text('src/a.txt'), 'mine');
    });

    test('replaces the placeholder with its own file: it is kept', () {
      onFirstReserve((placeholder) {
        File(placeholder).deleteSync();
        File(placeholder).createSync();
      });
      final result = m.move(tree.real('src/a.txt'), tree.real('dst/a.txt'));
      expect(result.errorKind, FileErrorKind.targetExists);
      expect(tree.bytesOf('dst/a.txt'), isEmpty);
      expect(text('src/a.txt'), 'mine');
    });

    test('the source disappears: the placeholder is set aside', () {
      onFirstReserve((_) => File(tree.real('src/a.txt')).deleteSync());
      final result = m.move(tree.real('src/a.txt'), tree.real('dst/a.txt'));
      expect(result.errorKind, FileErrorKind.notFound);
      expect(tree.namesIn('dst'), ['taken.txt']);
      expect(tree.namesIn('aside-parent/aside'), ['p0']);
      expect(tree.bytesOf('aside-parent/aside/p0'), isEmpty);
    });

    test('a set-aside name that is taken is skipped', () {
      tree.file('aside-parent/aside/p0', text: 'earlier');
      onFirstReserve((_) => File(tree.real('src/a.txt')).deleteSync());
      m.move(tree.real('src/a.txt'), tree.real('dst/a.txt'));
      expect(text('aside-parent/aside/p0'), 'earlier');
      expect(tree.namesIn('aside-parent/aside'), ['p0', 'p1']);
      expect(tree.namesIn('dst'), ['taken.txt']);
    });

    test('a placeholder that is no longer ours is not set aside', () {
      onFirstReserve((placeholder) {
        File(tree.real('src/a.txt')).deleteSync();
        File(placeholder).writeAsStringSync('other app');
      });
      final result = m.move(tree.real('src/a.txt'), tree.real('dst/a.txt'));
      expect(result.errorKind, FileErrorKind.targetExists);
      expect(text('dst/a.txt'), 'other app');
      expect(tree.namesIn('aside-parent/aside'), isEmpty);
    });
  });
}
