import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  FileEntry full({
    SourceId sourceId = testSource,
    String path = 'Download/IMG_1.jpg',
    int size = 10,
    DateTime? modifiedAt,
    DateTime? capturedAt,
    String? mimeType = 'image/jpeg',
    String? partialHash = 'p',
    String? fullHash = 'f',
    ScanId? lastSeenScanId = const ScanId('scan1'),
  }) => fileEntry(
    path,
    sourceId: sourceId,
    size: size,
    modifiedAt: modifiedAt,
    capturedAt: capturedAt ?? DateTime.utc(2023),
    mimeType: mimeType,
    partialHash: partialHash,
    fullHash: fullHash,
    lastSeenScanId: lastSeenScanId,
  );

  test('value equality covers every field', () {
    expectValueEquality(full, {
      'sourceId': full(sourceId: const SourceId('other')),
      'path': full(path: 'Download/IMG_2.jpg'),
      'size': full(size: 11),
      'modifiedAt': full(modifiedAt: DateTime.utc(2020)),
      'capturedAt': full(capturedAt: DateTime.utc(2022)),
      'mimeType': full(mimeType: 'image/png'),
      'no mimeType': full(mimeType: null),
      'partialHash': full(partialHash: 'p2'),
      'fullHash': full(fullHash: 'f2'),
      'lastSeenScanId': full(lastSeenScanId: const ScanId('scan2')),
      'no lastSeenScanId': full(lastSeenScanId: null),
    });
  });

  test('name and extension are derived from the path', () {
    final entry = fileEntry('Download/Report.Final.PDF');
    expect(entry.name, 'Report.Final.PDF');
    expect(entry.extension, 'pdf');
  });

  test('stores dates in UTC', () {
    final entry = fileEntry(
      'a.jpg',
      modifiedAt: testTime.toLocal(),
      capturedAt: testTime.toLocal(),
    );
    expect(entry.modifiedAt.isUtc, isTrue);
    expect(entry.capturedAt!.isUtc, isTrue);
    expect(entry, fileEntry('a.jpg', capturedAt: testTime));
  });

  test('fingerprint takes size, modifiedAt and fullHash', () {
    final entry = fileEntry('a.jpg', size: 5, fullHash: 'h');
    expect(
      entry.fingerprint,
      Fingerprint(size: 5, modifiedAt: testTime, fullHash: 'h'),
    );
    expect(fileEntry('a.jpg').fingerprint.fullHash, isNull);
  });

  test('rejects the source root as a path', () {
    expect(
      () => FileEntry(
        sourceId: testSource,
        path: LogicalPath.root,
        size: 1,
        modifiedAt: testTime,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a negative size', () {
    expect(() => fileEntry('a.txt', size: -1), throwsArgumentError);
  });

  test('withPartialHash and withFullHash change only that hash', () {
    final entry = full(partialHash: null, fullHash: null);
    expect(entry.withPartialHash('p'), full(fullHash: null));
    expect(entry.withFullHash('f'), full(partialHash: null));
    expect(entry.withPartialHash('p').withFullHash('f'), full());
  });
}
