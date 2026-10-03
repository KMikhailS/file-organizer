import 'package:file_organizer/core/layout/layout.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/layout_fixtures.dart';
import '../../support/model_fixtures.dart';

void main() {
  final template = russianTemplate();

  Classification classified(Category category, {LogicalPath? subfolder}) =>
      Classification(
        category: category,
        confidence: 1,
        origin: ClassificationOrigin.rule,
        reason: 'test',
        subfolder: subfolder,
      );

  Placement place(
    String path,
    Category category, {
    DateTime? modifiedAt,
    DateTime? capturedAt,
    LayoutTemplate? using,
    LogicalPath? subfolder,
  }) => (using ?? template).place(
    fileEntry(path, modifiedAt: modifiedAt, capturedAt: capturedAt),
    classified(category, subfolder: subfolder),
  );

  group('target folder for each category', () {
    final modified = DateTime.utc(2023, 6, 2);
    const table = {
      Category.documents: 'Документы',
      Category.photos: 'Фото/2023',
      Category.videos: 'Видео/2023',
      Category.screenshots: 'Скриншоты/2023',
      Category.music: 'Музыка',
      Category.archives: 'Архивы',
      Category.installers: 'Установщики',
      Category.other: 'Прочее',
    };
    for (final MapEntry(key: category, value: folder) in table.entries) {
      test('${category.name} -> $folder', () {
        expect(
          place('Download/file.x', category, modifiedAt: modified),
          PlaceIn(p(folder)),
        );
      });
    }
  });

  test('unresolved files stay where they are', () {
    expect(
      place('Download/data.xyz', Category.unresolved),
      const StaysInPlace(StayReason.unresolved),
    );
  });

  group('year', () {
    test('comes from the capture date when there is one', () {
      expect(
        place(
          'Download/IMG.jpg',
          Category.photos,
          capturedAt: DateTime.utc(2019, 8, 2),
          modifiedAt: DateTime.utc(2024, 2, 2),
        ),
        PlaceIn(p('Фото/2019')),
      );
    });

    test('else from the modification time', () {
      expect(
        place(
          'Download/clip.mp4',
          Category.videos,
          modifiedAt: DateTime.utc(2021, 12, 31, 23),
        ),
        PlaceIn(p('Видео/2021')),
      );
    });

    test('uses the year function: local time decides near midnight', () {
      // 2023-12-31 20:30 UTC is already 2024 in UTC+5.
      final local = russianTemplate(
        yearOf: (utc) => utc.add(const Duration(hours: 5)).year,
      );
      final shot = DateTime.utc(2023, 12, 31, 20, 30);
      expect(
        place('IMG.jpg', Category.photos, capturedAt: shot),
        PlaceIn(p('Фото/2023')),
      );
      expect(
        place('IMG.jpg', Category.photos, capturedAt: shot, using: local),
        PlaceIn(p('Фото/2024')),
      );
    });
  });

  test('a custom template root', () {
    final nested = russianTemplate(root: p('Sorted'));
    expect(
      place('Download/a.pdf', Category.documents, using: nested),
      PlaceIn(p('Sorted/Документы')),
    );
    expect(nested.targetFolders, contains(p('Sorted/Фото')));
  });

  test('an AI subfolder goes inside, after the year', () {
    expect(
      place('Download/a.pdf', Category.documents, subfolder: p('Налоги')),
      PlaceIn(p('Документы/Налоги')),
    );
    expect(
      place(
        'Download/a.jpg',
        Category.photos,
        modifiedAt: DateTime.utc(2024),
        subfolder: p('Отпуск'),
      ),
      PlaceIn(p('Фото/2024/Отпуск')),
    );
  });

  group('a file already in its folder', () {
    test('stays', () {
      expect(
        place('Документы/a.pdf', Category.documents),
        const StaysInPlace(StayReason.alreadyInPlace),
      );
      expect(
        place(
          'Фото/2024/a.jpg',
          Category.photos,
          modifiedAt: DateTime.utc(2024, 5),
        ),
        const StaysInPlace(StayReason.alreadyInPlace),
      );
    });

    test('regardless of case', () {
      expect(
        place('документы/a.pdf', Category.documents),
        const StaysInPlace(StayReason.alreadyInPlace),
      );
    });

    test('but not in the wrong year or a parent folder', () {
      expect(
        place(
          'Фото/2023/a.jpg',
          Category.photos,
          modifiedAt: DateTime.utc(2024, 5),
        ),
        PlaceIn(p('Фото/2024')),
      );
      expect(
        place('Фото/a.jpg', Category.photos, modifiedAt: DateTime.utc(2024)),
        PlaceIn(p('Фото/2024')),
      );
    });
  });

  test('target folders are the top-level template folders', () {
    expect(template.targetFolders, {
      for (final name in russianFolderNames.values) p(name),
    });
  });

  group('folder names', () {
    Map<Category, String> names(Map<Category, String> changes) => {
      ...russianFolderNames,
      ...changes,
    };

    test('come from the caller (any language)', () {
      final english = LayoutTemplate(
        folderNames: names({Category.documents: 'Documents'}),
      );
      expect(english.folderOf(Category.documents), p('Documents'));
    });

    test('must cover every category but unresolved', () {
      expect(
        () => LayoutTemplate(
          folderNames: {...russianFolderNames}..remove(Category.music),
        ),
        throwsArgumentError,
      );
      expect(
        () => LayoutTemplate(folderNames: names({Category.unresolved: 'X'})),
        throwsArgumentError,
      );
    });

    for (final bad in ['', 'a/b', '..', '.hidden']) {
      test('reject "$bad"', () {
        expect(
          () => LayoutTemplate(folderNames: names({Category.music: bad})),
          throwsArgumentError,
        );
      });
    }

    test('must differ regardless of case', () {
      expect(
        () => LayoutTemplate(folderNames: names({Category.music: 'фото'})),
        throwsArgumentError,
      );
    });
  });
}
