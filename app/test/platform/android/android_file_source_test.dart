import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/platform/android/android_file_source.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/platform/android/native_api.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/fs/temp_tree.dart';

/// AndroidFileSource on a temporary folder of the host with a fake
/// MediaStore. The real one runs on emulators (integration_test/android/).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TempTree tree;
  late _FakeStorage mediaStore;

  setUp(() async {
    tree = await TempTree.create();
    tree
      ..file('DCIM/a.jpg')
      ..file('DCIM/b.jpg')
      ..file('Download/c.pdf');
    mediaStore = _FakeStorage();
  });

  Future<AndroidFileSource> open({int pageSize = 500}) async {
    final source = await AndroidFileSource.open(
      sourceId: const SourceId('phone'),
      root: tree.root,
      clock: FakeClock(),
      native: AndroidNative(storage: mediaStore),
      pageSize: pageSize,
    );
    addTearDown(source.dispose);
    return source;
  }

  Future<List<FileListPage>> pages(AndroidFileSource source) async => [
    for (final result in await source.list().toList())
      (result as FileSuccess<FileListPage>).value,
  ];

  test('listings carry the capture dates of MediaStore', () async {
    final taken = DateTime.utc(2021, 5, 6, 4, 8, 9);
    mediaStore.dates = {tree.real('DCIM/a.jpg'): taken};
    final entries = (await pages(await open())).single.entries;
    expect(
      {for (final e in entries) e.path.value: e.capturedAt},
      {'DCIM/a.jpg': taken, 'DCIM/b.jpg': null, 'Download/c.pdf': null},
    );
    expect(entries.first.size, 'DCIM/a.jpg'.length);
  });

  test('one query per page, with the real paths of its files', () async {
    final listed = await pages(await open(pageSize: 2));
    expect(listed, hasLength(2));
    expect(mediaStore.asked, [
      [tree.real('DCIM/a.jpg'), tree.real('DCIM/b.jpg')],
      [tree.real('Download/c.pdf')],
    ]);
  });

  test('without MediaStore the listing goes on without dates', () async {
    mediaStore.error = PlatformException(code: 'channel-error');
    final entries = (await pages(await open())).single.entries;
    expect(entries, hasLength(3));
    expect(entries.every((e) => e.capturedAt == null), isTrue);
  });

  test(
    'capabilities: those of the POSIX adapter, plus capture dates',
    () async {
      final source = await open();
      expect(
        source.capabilities,
        const SourceCapabilities(
          canMove: true,
          canMkdir: true,
          canQuarantine: true,
          quarantineRestorable: true,
          providesCapturedAt: true,
        ),
      );
      expect(source.appFolders, {LogicalPath('.FileOrganizer')});
    },
  );

  test('changes go through the POSIX adapter', () async {
    final source = await open();
    expect(
      (await source.move(
        LogicalPath('DCIM/a.jpg'),
        LogicalPath('DCIM/b.jpg'),
      )).errorKind,
      FileErrorKind.targetExists,
    );
    expect(
      (await source.move(
        LogicalPath('DCIM/a.jpg'),
        LogicalPath('Download/a.jpg'),
      )).isSuccess,
      isTrue,
    );
    expect(tree.namesIn('Download'), ['a.jpg', 'c.pdf']);
  });
}

final class _FakeStorage implements StorageApi {
  Map<String, DateTime> dates = {};
  PlatformException? error;
  final List<List<String>> asked = [];

  @override
  Future<Map<String, int>> capturedDates(List<String> paths) async {
    asked.add(paths);
    if (error case final e?) {
      throw e;
    }
    return {
      for (final path in paths)
        if (dates.containsKey(path)) path: dates[path]!.millisecondsSinceEpoch,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
