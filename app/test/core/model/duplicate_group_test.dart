import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  FileEntry copy(
    String path, {
    SourceId sourceId = testSource,
    int size = 100,
  }) => fileEntry(path, sourceId: sourceId, size: size, fullHash: 'h');

  final a = copy('Download/a.jpg');
  final b = copy('Download/a (1).jpg');
  final c = copy('DCIM/a.jpg');

  DuplicateGroup makeGroup({
    String fullHash = 'h',
    List<FileEntry>? files,
    FileEntry? keeper,
    KeeperReason reason = KeeperReason.organizedLocation,
  }) => DuplicateGroup(
    fullHash: fullHash,
    files: files ?? [a, b, c],
    keeper: keeper ?? c,
    keeperReason: reason,
  );

  test('value equality covers every field', () {
    final d = fileEntry('x.jpg', size: 100, fullHash: 'h2');
    final e = fileEntry('y.jpg', size: 100, fullHash: 'h2');
    expectValueEquality(makeGroup, {
      'fullHash': makeGroup(fullHash: 'h2', files: [d, e], keeper: d),
      'files': makeGroup(files: [a, c]),
      'keeper': makeGroup(keeper: a),
      'keeperReason': makeGroup(reason: KeeperReason.alphabeticalPath),
    });
  });

  test('files are sorted by path, so input order does not matter', () {
    expect(makeGroup(files: [c, b, a]), makeGroup(files: [a, b, c]));
    expect(makeGroup().files.map((f) => f.path.value), [
      'DCIM/a.jpg',
      'Download/a (1).jpg',
      'Download/a.jpg',
    ]);
  });

  test('files are unmodifiable', () {
    expect(() => makeGroup().files.add(a), throwsUnsupportedError);
  });

  test('derived values', () {
    final g = makeGroup();
    expect(g.sourceId, testSource);
    expect(g.size, 100);
    expect(g.extras, [b, a]);
    expect(g.extras, isNot(contains(g.keeper)));
    expect(g.reclaimableBytes, 200);
  });

  group('rejects', () {
    test('a single file', () {
      expect(() => makeGroup(files: [c]), throwsArgumentError);
    });

    test('empty files', () {
      final x = copy('x', size: 0);
      final y = copy('y', size: 0);
      expect(() => makeGroup(files: [x, y], keeper: x), throwsArgumentError);
    });

    test('files from different sources', () {
      final other = copy('Download/a.jpg', sourceId: const SourceId('other'));
      expect(
        () => makeGroup(files: [a, other], keeper: a),
        throwsArgumentError,
      );
    });

    test('files of different sizes', () {
      final bigger = copy('big.jpg', size: 101);
      expect(
        () => makeGroup(files: [a, bigger], keeper: a),
        throwsArgumentError,
      );
    });

    test('a file with another hash', () {
      final other = fileEntry('o.jpg', size: 100, fullHash: 'x');
      expect(
        () => makeGroup(files: [a, other], keeper: a),
        throwsArgumentError,
      );
    });

    test('a file without a full hash', () {
      final unhashed = fileEntry('u.jpg', size: 100);
      expect(
        () => makeGroup(files: [a, unhashed], keeper: a),
        throwsArgumentError,
      );
    });

    test('the same path twice', () {
      expect(() => makeGroup(files: [a, a], keeper: a), throwsArgumentError);
    });

    test('a keeper outside the group', () {
      expect(
        () => makeGroup(files: [a, b], keeper: copy('elsewhere.jpg')),
        throwsArgumentError,
      );
    });
  });
}
