import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/platform/posix/posix_file_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fs/temp_tree.dart';
import 'file_source_contract.dart';

/// Runs the `FileSource` contract against the POSIX adapter on temporary
/// folders of the host. Part I of the adapter (stage 2, task 6) reads only;
/// the writing part of the contract joins in task 7.
void main() {
  group('PosixFileSource', () {
    fileSourceReadContract(_PosixFixture.create);
  });

  group('PosixFileSource, one item per page', () {
    fileSourceReadContract(() => _PosixFixture.create(pageSize: 1));
  });
}

final class _PosixFixture implements FileSourceFixture {
  _PosixFixture(this._tree, this.source);

  static Future<_PosixFixture> create({
    int pageSize = PosixFileSource.defaultPageSize,
  }) async {
    final tree = await TempTree.create();
    final source = PosixFileSource(
      sourceId: const SourceId('posix'),
      root: tree.root,
      pageSize: pageSize,
    );
    addTearDown(source.dispose);
    return _PosixFixture(tree, source);
  }

  final TempTree _tree;

  @override
  final PosixFileSource source;

  @override
  Future<void> givenFile(
    String path, {
    required List<int> bytes,
    required DateTime modifiedAt,
  }) async => _tree.file(path, bytes: bytes, modifiedAt: modifiedAt);

  @override
  Future<void> givenDir(String path) async => _tree.dir(path);
}
