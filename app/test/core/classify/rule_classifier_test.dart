import 'package:file_organizer/core/classify/classify.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';

void main() {
  final classifier = RuleClassifier();

  Category categoryOf(String path, {String? mime, RuleClassifier? using}) =>
      (using ?? classifier)
          .classifyFile(fileEntry(path, mimeType: mime))
          .category;

  group('by extension', () {
    const table = {
      'Download/report.pdf': Category.documents,
      'Download/letter.DOCX': Category.documents,
      'Download/table.xlsx': Category.documents,
      'Download/slides.pptx': Category.documents,
      'Download/notes.txt': Category.documents,
      'Download/data.csv': Category.documents,
      'Download/book.epub': Category.documents,
      'Download/scan.odt': Category.documents,
      'Download/memo.rtf': Category.documents,
      'Download/IMG_1.jpg': Category.photos,
      'Download/IMG_2.JPEG': Category.photos,
      'Download/IMG_3.heic': Category.photos,
      'Download/pic.png': Category.photos,
      'Download/pic.webp': Category.photos,
      'Download/raw.CR2': Category.photos,
      'Download/raw.nef': Category.photos,
      'Download/raw.arw': Category.photos,
      'Download/raw.dng': Category.photos,
      'Download/clip.mp4': Category.videos,
      'Download/clip.MOV': Category.videos,
      'Download/film.mkv': Category.videos,
      'Download/old.avi': Category.videos,
      'Download/web.webm': Category.videos,
      'Download/song.mp3': Category.music,
      'Download/song.flac': Category.music,
      'Download/song.m4a': Category.music,
      'Download/song.wav': Category.music,
      'Download/song.ogg': Category.music,
      'Download/song.aac': Category.music,
      'Download/backup.zip': Category.archives,
      'Download/backup.rar': Category.archives,
      'Download/backup.7z': Category.archives,
      'Download/backup.tar': Category.archives,
      'Download/backup.tar.gz': Category.archives,
      'Download/app.apk': Category.installers,
      'Download/setup.exe': Category.installers,
      'Download/setup.msi': Category.installers,
      'Download/app.dmg': Category.installers,
      'Download/app.pkg': Category.installers,
      'Download/app.deb': Category.installers,
      'Download/movie.torrent': Category.other,
      'Download/meeting.ics': Category.other,
      'Download/contact.vcf': Category.other,
      'Download/data.xyz': Category.unresolved,
      'Download/README': Category.unresolved,
      'Download/file.': Category.unresolved,
    };
    for (final MapEntry(key: path, value: category) in table.entries) {
      test('$path -> ${category.name}', () {
        expect(categoryOf(path), category);
      });
    }
  });

  group('screenshots', () {
    const table = {
      'Pictures/Screenshot_20240301-120000.png': Category.screenshots,
      'Desktop/Screenshot 2024-03-01 at 12.00.00.png': Category.screenshots,
      'Desktop/Screen Shot 2019-05-01 at 10.10.10.png': Category.screenshots,
      'Desktop/Снимок экрана 2024-03-01 120000.png': Category.screenshots,
      'Desktop/Скриншот 01-03-2024.jpg': Category.screenshots,
      'Download/screenshot-1.JPG': Category.screenshots,
      'Pictures/Screenshots/IMG_1.png': Category.screenshots,
      'Pictures/Скриншоты/a.jpg': Category.screenshots,
      'DCIM/Screenshots/b.webp': Category.screenshots,
      // Not screenshots.
      'Download/photo.png': Category.photos,
      'Pictures/Screenshots/recording.mp4': Category.videos,
      'Pictures/Screenshots/sub/a.png': Category.photos,
    };
    for (final MapEntry(key: path, value: category) in table.entries) {
      test('$path -> ${category.name}', () {
        expect(categoryOf(path), category);
      });
    }
  });

  group('contradicting signs give unresolved', () {
    test('a screenshot name on a non-image', () {
      expect(categoryOf('Download/Screenshot_2024.pdf'), Category.unresolved);
      expect(categoryOf('Download/screenshot.mp4'), Category.unresolved);
    });

    test('a MIME type of another media family', () {
      expect(categoryOf('a.pdf', mime: 'image/png'), Category.unresolved);
      expect(categoryOf('a.jpg', mime: 'application/pdf'), Category.unresolved);
      expect(categoryOf('a.mp3', mime: 'video/mp4'), Category.unresolved);
      expect(categoryOf('a.mp4', mime: 'audio/mpeg'), Category.unresolved);
    });

    test('a matching or generic MIME type is fine', () {
      expect(categoryOf('a.jpg', mime: 'image/jpeg'), Category.photos);
      expect(categoryOf('a.JPG', mime: 'IMAGE/JPEG'), Category.photos);
      expect(categoryOf('a.pdf', mime: 'application/pdf'), Category.documents);
      expect(categoryOf('a.mp4', mime: 'video/mp4'), Category.videos);
      expect(
        categoryOf('a.png', mime: 'application/octet-stream'),
        Category.photos,
      );
      expect(
        categoryOf('Screenshot_1.png', mime: 'image/png'),
        Category.screenshots,
      );
    });
  });

  group('user rules', () {
    test('come before the built-in rules', () {
      final rules = RuleClassifier(
        userRules: [
          ClassificationRule(
            id: 'pdf-books',
            category: Category.other,
            extensions: const {'pdf'},
            folder: p('Download/Books'),
          ),
        ],
      );
      expect(categoryOf('Download/Books/x.pdf', using: rules), Category.other);
      expect(categoryOf('Download/x.pdf', using: rules), Category.documents);
    });

    test('can classify unknown extensions and screenshots differently', () {
      final rules = RuleClassifier(
        userRules: [
          ClassificationRule(
            id: 'cad',
            category: Category.documents,
            extensions: const {'.DWG'},
          ),
          ClassificationRule(
            id: 'shots',
            category: Category.photos,
            nameContains: 'screenshot',
          ),
        ],
      );
      expect(categoryOf('plan.dwg', using: rules), Category.documents);
      expect(categoryOf('Screenshot_1.png', using: rules), Category.photos);
    });

    test('can keep files in place with unresolved', () {
      final rules = RuleClassifier(
        userRules: [
          ClassificationRule(
            id: 'keep-psd',
            category: Category.unresolved,
            extensions: const {'jpg'},
            nameContains: 'draft',
          ),
        ],
      );
      expect(categoryOf('Draft-cover.jpg', using: rules), Category.unresolved);
      expect(categoryOf('cover.jpg', using: rules), Category.photos);
    });

    test('the first matching rule wins', () {
      final rules = RuleClassifier(
        userRules: [
          ClassificationRule(
            id: '1',
            category: Category.archives,
            nameContains: 'backup',
          ),
          ClassificationRule(
            id: '2',
            category: Category.other,
            extensions: const {'pdf'},
          ),
        ],
      );
      expect(categoryOf('backup.pdf', using: rules), Category.archives);
      expect(categoryOf('x.pdf', using: rules), Category.other);
    });

    test('apply only to their source', () {
      final rules = RuleClassifier(
        userRules: [
          ClassificationRule(
            id: 'phone-pdf',
            category: Category.other,
            extensions: const {'pdf'},
            sourceId: const SourceId('phone'),
          ),
        ],
      );
      expect(categoryOf('x.pdf', using: rules), Category.documents);
      expect(
        rules
            .classifyFile(fileEntry('x.pdf', sourceId: const SourceId('phone')))
            .category,
        Category.other,
      );
    });
  });

  test('results: rule origin, confidence and reason', () {
    final pdf = classifier.classifyFile(fileEntry('a.pdf'));
    expect(pdf.origin, ClassificationOrigin.rule);
    expect(pdf.confidence, 1);
    expect(pdf.reason, 'extension .pdf');
    expect(pdf.subfolder, isNull);

    final unknown = classifier.classifyFile(fileEntry('a.xyz'));
    expect(unknown.confidence, 0);
    expect(unknown.reason, 'unknown extension .xyz');
  });

  test('classify keeps the order of requests', () async {
    final results = await classifier.classify([
      for (final path in ['a.pdf', 'b.mp3', 'c.xyz'])
        ClassificationRequest(file: fileEntry(path), zone: Zone.chaos),
    ]);
    expect(results.map((c) => c.category), [
      Category.documents,
      Category.music,
      Category.unresolved,
    ]);
  });

  test('no extension is listed in two categories', () {
    final seen = <String, Category>{};
    for (final MapEntry(key: category, value: extensions)
        in BuiltinRules.extensions.entries) {
      for (final ext in extensions) {
        expect(
          seen[ext],
          isNull,
          reason: '.$ext in ${seen[ext]} and $category',
        );
        seen[ext] = category;
      }
    }
  });
}
