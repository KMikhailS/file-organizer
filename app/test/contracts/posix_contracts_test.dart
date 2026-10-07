import 'package:file_organizer/platform/posix/no_replace_mover.dart';
import 'package:file_organizer/platform/posix/posix_file_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fs/posix_sources.dart';
import '../support/fs/temp_tree.dart';
import 'file_source_contract.dart';

/// Runs the `FileSource` contract against the POSIX adapter on temporary
/// folders of the host (Linux: case-sensitive, `renameat2` works), with
/// both move mechanisms of decision A.5.
void main() {
  group('PosixFileSource', () {
    fileSourceContract(_PosixFixture.create);
  });

  group('PosixFileSource, one item per page', () {
    fileSourceReadContract(() => _PosixFixture.create(pageSize: 1));
  });

  group('PosixFileSource, reserve then rename', () {
    fileSourceWriteContract(
      () => _PosixFixture.create(mechanism: MoveMechanism.reserveThenRename),
    );
  });
}

final class _PosixFixture implements FileSourceFixture {
  _PosixFixture(this._tree, this.source);

  static Future<_PosixFixture> create({
    int pageSize = PosixFileSource.defaultPageSize,
    MoveMechanism? mechanism,
  }) async {
    final tree = await TempTree.create();
    final source = await openPosix(
      tree.root,
      pageSize: pageSize,
      mechanism: mechanism,
    );
    expect(source.moveMechanism, mechanism ?? MoveMechanism.renameNoReplace);
    return _PosixFixture(tree, source);
  }

  final TempTree _tree;

  @override
  final PosixFileSource source;

  @override
  bool get caseInsensitive => false;

  @override
  Future<void> givenFile(
    String path, {
    required List<int> bytes,
    required DateTime modifiedAt,
  }) async => _tree.file(path, bytes: bytes, modifiedAt: modifiedAt);

  @override
  Future<void> givenDir(String path) async => _tree.dir(path);
}
