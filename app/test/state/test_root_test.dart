import 'dart:io';

import 'package:file_organizer/state/test_root.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const folder = '/storage/emulated/0/FileOrganizerTest';

  test('a release build always works on the real storage', () {
    expect(testStorageRoot(folder, debug: false), isNull);
    expect(testStorageRoot('', debug: false), isNull);
  });

  test('a debug build without the define works on the real storage', () {
    expect(testStorageRoot('', debug: true), isNull);
  });

  test('a debug build with the define: that folder', () {
    expect(testStorageRoot(folder, debug: true), folder);
    expect(testStorageRoot('$folder/', debug: true), folder);
  });

  test('only a folder inside the shared storage', () {
    for (final wrong in [
      '/storage/emulated/0',
      '/storage/emulated/0/',
      '/sdcard/FileOrganizerTest',
      'FileOrganizerTest',
      '/storage/emulated/0/../0/Download',
      '/data/data/app',
    ]) {
      expect(
        () => testStorageRoot(wrong, debug: true),
        throwsArgumentError,
        reason: wrong,
      );
    }
  });

  test('the app passes whether it is a debug build, never a constant', () {
    // A release build must ignore FO_TEST_ROOT: main.dart decides with
    // kDebugMode, which is false in release.
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('testStorageRoot(_testRoot, debug: kDebugMode)'));
  });
}
