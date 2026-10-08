// AndroidFileSource on the shared storage of an emulator
// (docs/stage2_android.md, sections 5.4 and 5.11). Run it with
// run_android.sh: the script grants "All files access", puts an indexed
// photo into the test folder, and removes the folder at the end.
import 'dart:io';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/platform/android/android_file_source.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/platform/services/system_clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/contracts/file_source_contract.dart';

/// The test folder in shared storage that the script prepares and removes.
const String testRoot = '/storage/emulated/0/FileOrganizerTest';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final native = AndroidNative();
  var sources = 0;

  setUpAll(() async {
    expect(
      await native.hasAllFilesAccess(),
      const NativeOk(true),
      reason: 'run via run_android.sh',
    );
  });

  Future<AndroidFileSource> open(String root, {int? pageSize}) async {
    final source = await AndroidFileSource.open(
      sourceId: const SourceId('phone'),
      root: root,
      clock: const SystemClock(),
      native: native,
      pageSize: pageSize ?? 500,
    );
    addTearDown(source.dispose);
    return source;
  }

  /// A fresh, empty folder for one source in the test folder.
  Future<String> freshRoot() async {
    final dir = Directory('$testRoot/contract/${sources++}');
    await dir.create(recursive: true);
    return dir.path;
  }

  group('contract', () {
    fileSourceContract(
      () async => _AndroidFixture(await open(await freshRoot())),
    );
  });

  group('contract, one item per page', () {
    fileSourceReadContract(
      () async => _AndroidFixture(await open(await freshRoot(), pageSize: 1)),
    );
  });

  group('shared storage', () {
    const photo = 'photo.jpg';
    // EXIF of the fixture: 2021:05:06 07:08:09, offset +03:00.
    final taken = DateTime.utc(2021, 5, 6, 4, 8, 9);

    test('the probe finds a way to move without replacing', () async {
      final source = await open(await freshRoot());
      // ignore: avoid_print, reported by run_android.sh.
      print('ANDROID|mechanism=${source.moveMechanism?.name}');
      expect(source.moveMechanism, isNotNull, reason: source.probeProblem);
      expect(
        File('${source.root}/.FileOrganizer/.nomedia').existsSync(),
        isTrue,
      );
    });

    test('the listing carries the capture date of an indexed photo', () async {
      final source = await open('$testRoot/media');
      final entries = [
        for (final result in await source.list().toList())
          ...(result as FileSuccess<FileListPage>).value.entries,
      ];
      expect([for (final e in entries) e.path.value], [photo]);
      expect(entries.single.capturedAt, taken);
    });

    test('MediaStore follows a move', () async {
      final source = await open('$testRoot/media');
      expect((await source.mkdir(LogicalPath('moved'))).isSuccess, isTrue);
      expect(
        (await source.move(
          LogicalPath(photo),
          LogicalPath('moved/$photo'),
        )).isSuccess,
        isTrue,
      );
      const from = '$testRoot/media/$photo';
      const to = '$testRoot/media/moved/$photo';
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      var dates = <String, DateTime>{};
      while (DateTime.now().isBefore(deadline)) {
        dates = switch (await native.capturedDates([from, to])) {
          NativeOk(:final value) => value,
          NativeFailed(:final code) => fail(code),
        };
        if (dates.length == 1 && dates.containsKey(to)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(dates, {to: taken});
    });
  });
}

final class _AndroidFixture implements FileSourceFixture {
  _AndroidFixture(this.source);

  @override
  final AndroidFileSource source;

  /// Shared storage ignores the case of names.
  @override
  bool get caseInsensitive => true;

  @override
  Future<void> givenFile(
    String path, {
    required List<int> bytes,
    required DateTime modifiedAt,
  }) async {
    final file = File('${source.root}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    await file.setLastModified(modifiedAt);
  }

  @override
  Future<void> givenDir(String path) =>
      Directory('${source.root}/$path').create(recursive: true);
}
