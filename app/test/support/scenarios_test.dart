import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fs/in_memory_file_source.dart';
import 'scenarios.dart';

void main() {
  Future<String> hash(
    InMemoryFileSource fs,
    String path, {
    bool partial = false,
  }) async {
    final result = partial
        ? await fs.partialHash(LogicalPath(path))
        : await fs.fullHash(LogicalPath(path));
    return (result as FileSuccess<String>).value;
  }

  group('typical Download folder', () {
    final fs = InMemoryFileSource()..withTypicalDownloadFolder();

    test('contains a duplicate with a copy marker', () async {
      expect(
        await hash(fs, 'Download/invoice_2024 (1).pdf'),
        await hash(fs, 'Download/invoice_2024.pdf'),
      );
    });

    test(
      'contains a same-size decoy that only the full hash tells apart',
      () async {
        const a = 'Download/holiday.mp4';
        const b = 'Download/holiday-edit.mp4';
        expect(fs.readBytes(a).length, fs.readBytes(b).length);
        expect(
          await hash(fs, b, partial: true),
          await hash(fs, a, partial: true),
        );
        expect(await hash(fs, b), isNot(await hash(fs, a)));
      },
    );

    test('contains an empty file and excluded folders', () {
      expect(fs.readBytes('Download/empty.txt'), isEmpty);
      expect(fs.isDirectory('Download/.cache'), isTrue);
      expect(fs.isDirectory('Download/project/node_modules'), isTrue);
    });

    test('can be placed at the source root', () {
      final root = InMemoryFileSource()..withTypicalDownloadFolder(root: '');
      expect(root.isFile('invoice_2024.pdf'), isTrue);
    });
  });

  group('phone with duplicate photos', () {
    final fs = phoneStorage();

    test('is case-insensitive Android storage', () {
      expect(fs.caseSensitive, isFalse);
      expect(fs.capabilities, androidMediaStoreCapabilities);
      expect(fs.isFile('dcim/camera/img_20230714_093000.JPG'), isTrue);
    });

    test('each camera photo has copies elsewhere', () async {
      final camera = await hash(fs, 'DCIM/Camera/IMG_20230714_093000.jpg');
      expect(
        await hash(
          fs,
          'Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/'
          'IMG-20230715-WA0001.jpg',
        ),
        camera,
      );
      expect(
        await hash(fs, 'Telegram/Telegram Images/photo_2024-02-04.jpg'),
        await hash(fs, 'DCIM/Camera/IMG_20240203_093000.jpg'),
      );
      expect(
        await hash(fs, 'Download/IMG_20240518_093000 (1).jpg'),
        await hash(fs, 'DCIM/Camera/IMG_20240518_093000.jpg'),
      );
    });

    test('lists capture dates of camera photos', () async {
      final entries = [
        for (final page in await fs.list().toList())
          ...(page as FileSuccess<FileListPage>).value.entries,
      ];
      final camera = entries.where((e) => e.path.value.startsWith('DCIM/'));
      expect(camera.map((e) => e.capturedAt), everyElement(isNotNull));
    });
  });

  test('organized document archive is uniform and nested', () {
    final fs = InMemoryFileSource()..withOrganizedDocumentArchive();
    final files = fs.snapshot().files.keys;
    expect(files, hasLength(12));
    expect(files, everyElement(startsWith('Documents/')));
    expect(fs.isDirectory('Documents/Taxes/2023'), isTrue);
  });

  test('scenarios combine in one source', () {
    final fs = InMemoryFileSource()
      ..withTypicalDownloadFolder()
      ..withOrganizedDocumentArchive();
    expect(fs.isFile('Download/notes.txt'), isTrue);
    expect(fs.isFile('Documents/Car/insurance.pdf'), isTrue);
  });
}
