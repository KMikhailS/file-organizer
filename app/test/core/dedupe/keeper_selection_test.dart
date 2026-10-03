import 'package:file_organizer/core/dedupe/keeper_selection.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';

void main() {
  final early = DateTime.utc(2023);
  final late = DateTime.utc(2024);

  /// Zones by folder: `Org/...` organized, `Tpl/...` target, else chaos.
  Zone zoneOf(FileEntry f) => switch (f.path.segments.first) {
    'Org' => Zone.organized,
    'Tpl' => Zone.target,
    _ => Zone.chaos,
  };

  FileEntry copy(String path, {DateTime? modifiedAt}) =>
      fileEntry(path, modifiedAt: modifiedAt ?? early, fullHash: 'h');

  void expectKeeper(List<FileEntry> files, String keeper, KeeperReason reason) {
    for (final order in [files, files.reversed.toList()]) {
      final choice = chooseKeeper(order, zoneOf);
      expect(choice.keeper.path.value, keeper);
      expect(choice.reason, reason);
    }
  }

  group('each rule on its own (all earlier rules tied)', () {
    test('1. organized or target folder beats chaos', () {
      expectKeeper(
        [copy('Download/a.jpg'), copy('Org/a.jpg')],
        'Org/a.jpg',
        KeeperReason.organizedLocation,
      );
      expectKeeper(
        [copy('Download/a.jpg'), copy('Tpl/a.jpg')],
        'Tpl/a.jpg',
        KeeperReason.organizedLocation,
      );
    });

    test('2. earlier modification time', () {
      expectKeeper(
        [copy('Download/a.jpg', modifiedAt: late), copy('Download/b.jpg')],
        'Download/b.jpg',
        KeeperReason.earliestModified,
      );
    });

    test('3. name without a copy marker', () {
      expectKeeper(
        [copy('Download/a (1).jpg'), copy('Download/b.jpg')],
        'Download/b.jpg',
        KeeperReason.notACopy,
      );
    });

    test('4. shorter path', () {
      expectKeeper(
        [copy('Download/long-name.jpg'), copy('Download/b.jpg')],
        'Download/b.jpg',
        KeeperReason.shortestPath,
      );
    });

    test('5. alphabetical path', () {
      expectKeeper(
        [copy('Download/b.jpg'), copy('Download/a.jpg')],
        'Download/a.jpg',
        KeeperReason.alphabeticalPath,
      );
    });
  });

  group('rule order', () {
    test('location beats an earlier time in a chaos zone', () {
      expectKeeper(
        [copy('Download/a.jpg'), copy('Org/a.jpg', modifiedAt: late)],
        'Org/a.jpg',
        KeeperReason.organizedLocation,
      );
    });

    test('an earlier time beats a copy marker', () {
      expectKeeper(
        [copy('Download/a.jpg', modifiedAt: late), copy('Download/a (1).jpg')],
        'Download/a (1).jpg',
        KeeperReason.earliestModified,
      );
    });

    test('a copy marker beats a shorter path', () {
      expectKeeper(
        [copy('Download/x (1).jpg'), copy('Download/original-name.jpg')],
        'Download/original-name.jpg',
        KeeperReason.notACopy,
      );
    });

    test('organized and target folders rank the same', () {
      expectKeeper(
        [copy('Org/aa.jpg'), copy('Tpl/a.jpg')],
        'Tpl/a.jpg',
        KeeperReason.shortestPath,
      );
    });
  });

  test('the reason compares the keeper with the runner-up', () {
    // Org wins by location over Download, but the runner-up is the other
    // organized copy, beaten only by time.
    expectKeeper(
      [
        copy('Download/a.jpg'),
        copy('Org/x/a.jpg'),
        copy('Org/y/a.jpg', modifiedAt: late),
      ],
      'Org/x/a.jpg',
      KeeperReason.earliestModified,
    );
  });

  test('the result does not depend on the input order', () {
    final files = [
      copy('Download/c.jpg'),
      copy('Download/a (1).jpg'),
      copy('Download/b.jpg'),
      copy('Download/a.jpg'),
    ];
    final expected = chooseKeeper(files, zoneOf);
    for (var shift = 1; shift < files.length; shift++) {
      final rotated = [...files.skip(shift), ...files.take(shift)];
      expect(chooseKeeper(rotated, zoneOf), expected);
    }
    expect(expected.keeper.path.value, 'Download/a.jpg');
  });

  test('rejects fewer than two files and excluded files', () {
    expect(() => chooseKeeper([copy('a')], zoneOf), throwsArgumentError);
    expect(
      () => chooseKeeper([copy('a'), copy('b')], (_) => Zone.excluded),
      throwsArgumentError,
    );
  });
}
