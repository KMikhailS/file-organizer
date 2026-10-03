import 'package:file_organizer/core/dedupe/copy_marker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const copies = [
    'photo (1).jpg',
    'photo(2).jpg',
    'photo (12).JPG',
    'report - Copy.docx',
    'report - Copy (2).docx',
    'report - copy.docx',
    'report copy.txt',
    'report copy 2.txt',
    'report_copy.txt',
    'Copy of report.txt',
    'copy of report.txt',
    'отчёт — копия.docx',
    'отчёт - копия (3).docx',
    'Копия отчёт.docx',
    'Bericht - Kopie.pdf',
    'archive (1)',
  ];
  const originals = [
    'photo.jpg',
    'photo1.jpg',
    'photo (a).jpg',
    'photocopy.pdf',
    'copycat.txt',
    'Copyright.txt',
    'report-final.docx',
    'IMG_20240101.jpg',
    '.copy',
    '(1)report.txt',
  ];

  for (final name in copies) {
    test('"$name" is a copy', () => expect(hasCopyMarker(name), isTrue));
  }
  for (final name in originals) {
    test('"$name" is not a copy', () => expect(hasCopyMarker(name), isFalse));
  }
}
