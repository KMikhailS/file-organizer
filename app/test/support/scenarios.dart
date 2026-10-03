import 'package:file_organizer/core/model/model.dart';

import 'fs/in_memory_file_source.dart';

/// Ready-made file trees for tests. Each `with...` method adds files to a
/// source and returns it, so scenarios can be combined:
///
/// ```dart
/// final fs = InMemoryFileSource()
///   ..withTypicalDownloadFolder()
///   ..withOrganizedDocumentArchive();
/// ```
extension Scenarios on InMemoryFileSource {
  /// A desktop `Download` folder with the usual mess:
  /// - documents, photos, a screenshot, a video, music, an archive and
  ///   installers;
  /// - a duplicate with a copy marker: `invoice_2024 (1).pdf` has the same
  ///   content as `invoice_2024.pdf` but is newer;
  /// - a large video and a decoy of the same size with the same first and
  ///   last 64 KB but a different middle (same partial hash, different full
  ///   hash);
  /// - files the rules cannot classify: `data.xyz`, `README`;
  /// - an empty file `empty.txt` (never a duplicate);
  /// - a hidden folder `.cache` and a `node_modules` folder inside a
  ///   project (excluded zones).
  InMemoryFileSource withTypicalDownloadFolder({String root = 'Download'}) {
    String at(String name) => root.isEmpty ? name : '$root/$name';
    DateTime day(int month, int dayOfMonth) =>
        DateTime.utc(2024, month, dayOfMonth, 12);

    const invoice = 'invoice 2024: 1250.00 EUR';
    return this
      ..addFile(at('invoice_2024.pdf'), text: invoice, modifiedAt: day(1, 15))
      ..addFile(
        at('invoice_2024 (1).pdf'),
        text: invoice,
        modifiedAt: day(2, 1),
      )
      ..addFile(at('Report.DOCX'), modifiedAt: day(3, 3))
      ..addFile(at('notes.txt'), modifiedAt: day(3, 4))
      ..addFile(at('table.xlsx'), modifiedAt: day(3, 5))
      ..addFile(
        at('IMG_20240512_101500.jpg'),
        modifiedAt: day(5, 20),
        capturedAt: DateTime.utc(2024, 5, 12, 10, 15),
      )
      ..addFile(at('photo.png'), modifiedAt: DateTime.utc(2023, 7, 2))
      ..addFile(at('Screenshot_20240301-120000.png'), modifiedAt: day(3, 1))
      ..addFile(at('song.mp3'), modifiedAt: day(4, 2))
      ..addFile(at('backup.zip'), modifiedAt: day(4, 3))
      ..addFile(at('setup.exe'), modifiedAt: day(4, 4))
      ..addFile(at('app-release.apk'), modifiedAt: day(4, 5))
      ..addFile(
        at('holiday.mp4'),
        bytes: largeContent(seed: 1, size: 200 * 1024),
        modifiedAt: day(6, 1),
      )
      ..addFile(
        at('holiday-edit.mp4'),
        bytes: largeContent(seed: 1, size: 200 * 1024, middleSeed: 2),
        modifiedAt: day(6, 2),
      )
      ..addFile(at('data.xyz'), modifiedAt: day(4, 6))
      ..addFile(at('README'), modifiedAt: day(4, 7))
      ..addFile(at('empty.txt'), bytes: const [], modifiedAt: day(4, 8))
      ..addFile(at('.cache/thumbs.db'), modifiedAt: day(4, 9))
      ..addFile(
        at('project/node_modules/left-pad/index.js'),
        modifiedAt: day(4, 10),
      )
      ..addFile(at('project/main.dart'), modifiedAt: day(4, 11));
  }

  /// An Android phone with duplicate photos:
  /// - camera photos in `DCIM/Camera` with capture dates in 2023 and 2024;
  /// - the same photos received again via WhatsApp and Telegram (newer
  ///   modification time, other names) and a `(1)` copy in `Download`;
  /// - screenshots in `Pictures/Screenshots`;
  /// - app data in `Android/data` (excluded).
  ///
  /// Use with `caseSensitive: false` and Android capabilities to mimic real
  /// phone storage; see [phoneStorage].
  InMemoryFileSource withPhoneDuplicatePhotos() {
    DateTime shot(int year, int month, int day) =>
        DateTime.utc(year, month, day, 9, 30);

    final beach = largeContent(seed: 10, size: 150 * 1024);
    final cat = largeContent(seed: 11, size: 90 * 1024);
    final cake = largeContent(seed: 12, size: 120 * 1024);
    return this
      ..addFile(
        'DCIM/Camera/IMG_20230714_093000.jpg',
        bytes: beach,
        modifiedAt: shot(2023, 7, 14),
        capturedAt: shot(2023, 7, 14),
      )
      ..addFile(
        'DCIM/Camera/IMG_20240203_093000.jpg',
        bytes: cat,
        modifiedAt: shot(2024, 2, 3),
        capturedAt: shot(2024, 2, 3),
      )
      ..addFile(
        'DCIM/Camera/IMG_20240518_093000.jpg',
        bytes: cake,
        modifiedAt: shot(2024, 5, 18),
        capturedAt: shot(2024, 5, 18),
      )
      ..addFile(
        'Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/'
        'IMG-20230715-WA0001.jpg',
        bytes: beach,
        modifiedAt: shot(2023, 7, 15),
      )
      ..addFile(
        'Telegram/Telegram Images/photo_2024-02-04.jpg',
        bytes: cat,
        modifiedAt: shot(2024, 2, 4),
      )
      ..addFile(
        'Download/IMG_20240518_093000 (1).jpg',
        bytes: cake,
        modifiedAt: shot(2024, 5, 20),
      )
      ..addFile(
        'Pictures/Screenshots/Screenshot_20240601-101010.png',
        modifiedAt: shot(2024, 6, 1),
      )
      ..addFile(
        'Android/data/com.example.app/cache/blob.bin',
        modifiedAt: shot(2024, 6, 2),
      );
  }

  /// A folder the user organized: `Documents` with topic and year
  /// subfolders, all documents. Must never be touched.
  InMemoryFileSource withOrganizedDocumentArchive({String root = 'Documents'}) {
    var day = 0;
    DateTime next() => DateTime.utc(2022).add(Duration(days: day += 9));
    for (final path in [
      'Taxes/2022/declaration.pdf',
      'Taxes/2022/receipts.pdf',
      'Taxes/2023/declaration.pdf',
      'Taxes/2023/receipts.pdf',
      'Car/insurance.pdf',
      'Car/service-history.xlsx',
      'Car/registration.pdf',
      'Work/Contracts/contract-2022.docx',
      'Work/Contracts/contract-2023.docx',
      'Work/cv.pdf',
      'Home/lease.pdf',
      'Home/utilities.xlsx',
    ]) {
      addFile('$root/$path', modifiedAt: next());
    }
    return this;
  }
}

/// Phone storage: case-insensitive, Android capabilities, with
/// [Scenarios.withPhoneDuplicatePhotos].
InMemoryFileSource phoneStorage({
  SourceId sourceId = const SourceId('phone'),
}) => InMemoryFileSource(
  sourceId: sourceId,
  capabilities: androidMediaStoreCapabilities,
  caseSensitive: false,
)..withPhoneDuplicatePhotos();

/// Deterministic pseudo-random content of [size] bytes. With [middleSeed],
/// everything except the first and last 64 KB comes from that seed, so the
/// partial hash matches the content of [seed] but the full hash does not.
List<int> largeContent({
  required int seed,
  required int size,
  int? middleSeed,
}) {
  const edge = 64 * 1024;
  int byteAt(int s, int i) => ((i * 31 + s * 7919) ^ (i >> 8)) & 0xff;
  return List<int>.generate(size, (i) {
    final inMiddle = i >= edge && i < size - edge;
    return byteAt(inMiddle && middleSeed != null ? middleSeed : seed, i);
  });
}
