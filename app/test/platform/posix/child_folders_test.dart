import 'dart:io';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/platform/posix/child_folders.dart';
import 'package:file_organizer/platform/posix/posix_paths.dart';
import 'package:flutter_test/flutter_test.dart';

/// The folders inside a folder, for the folder picker of the settings
/// (docs/stage2_android.md, 5.23), on a real temporary folder.
void main() {
  late Directory root;
  late PosixPaths paths;

  setUp(() {
    root = Directory.systemTemp.createTempSync('fo_child_folders_');
    addTearDown(() => root.deleteSync(recursive: true));
    paths = PosixPaths(root.path);
    for (final folder in [
      'Download/Telegram',
      'Download/apps',
      'DCIM/Camera',
      'documents',
      '.FileOrganizer',
      'Elsewhere/inner',
    ]) {
      Directory('${root.path}/$folder').createSync(recursive: true);
    }
    File('${root.path}/Download/a.pdf').writeAsStringSync('a');
    File('${root.path}/notes.txt').writeAsStringSync('n');
    Link('${root.path}/Shortcut').createSync('${root.path}/Elsewhere');
  });

  Future<List<String>> ok(String folder) async =>
      switch (await childFolders(paths, LogicalPath(folder))) {
        FileSuccess(:final value) => value,
        FileFailure(:final error) => fail('$error'),
      };

  Future<FileErrorKind?> kindOf(String folder) async =>
      switch (await childFolders(paths, LogicalPath(folder))) {
        FileSuccess() => null,
        FileFailure(:final error) => error.kind,
      };

  test('the folders of the root: no files, no hidden folders, no links; '
      'sorted ignoring case', () async {
    expect(await ok(''), ['DCIM', 'documents', 'Download', 'Elsewhere']);
  });

  test('the folders of a folder', () async {
    expect(await ok('Download'), ['apps', 'Telegram']);
    expect(await ok('DCIM/Camera'), isEmpty);
  });

  test('a link to a folder is never entered', () async {
    expect(await kindOf('Shortcut'), FileErrorKind.wrongType);
    expect(await kindOf('Shortcut/inner'), FileErrorKind.wrongType);
  });

  test('a missing folder and a file are not folders', () async {
    expect(await kindOf('Missing'), FileErrorKind.notFound);
    expect(await kindOf('notes.txt'), FileErrorKind.wrongType);
  });
}
