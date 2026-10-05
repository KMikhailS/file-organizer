import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/layout_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  test('defaults: 30 days of quarantine, no folder names, system language', () {
    final settings = Settings();
    expect(settings.quarantineRetention, const Duration(days: 30));
    expect(settings.layoutFolderNames, isNull);
    expect(settings.uiLocale, isNull);
  });

  test('value equality covers every field', () {
    expectValueEquality(
      () => Settings(
        quarantineRetention: const Duration(days: 7),
        layoutFolderNames: {...russianFolderNames},
        uiLocale: 'ru',
      ),
      {
        'quarantineRetention': Settings(
          layoutFolderNames: russianFolderNames,
          uiLocale: 'ru',
        ),
        'layoutFolderNames': Settings(
          quarantineRetention: const Duration(days: 7),
          layoutFolderNames: {...russianFolderNames, Category.other: 'Разное'},
          uiLocale: 'ru',
        ),
        'layoutFolderNames unset': Settings(
          quarantineRetention: const Duration(days: 7),
          uiLocale: 'ru',
        ),
        'uiLocale': Settings(
          quarantineRetention: const Duration(days: 7),
          layoutFolderNames: russianFolderNames,
          uiLocale: 'en',
        ),
      },
    );
  });

  test('keeps the quarantine at least a day', () {
    expect(
      () => Settings(quarantineRetention: const Duration(hours: 23)),
      throwsArgumentError,
    );
    expect(
      Settings(quarantineRetention: const Duration(days: 1))
          .quarantineRetention,
      const Duration(days: 1),
    );
  });

  group('layout folder names follow the template rules', () {
    final broken = <String, Map<Category, String>>{
      'a category without a name': {...russianFolderNames}
        ..remove(Category.music),
      'a name for unresolved': {
        ...russianFolderNames,
        Category.unresolved: 'Разобрать',
      },
      'two folders': {...russianFolderNames, Category.music: 'Медиа/Музыка'},
      'a hidden folder': {...russianFolderNames, Category.music: '.Музыка'},
      'an empty name': {...russianFolderNames, Category.music: ''},
      'the same name twice, ignoring case': {
        ...russianFolderNames,
        Category.music: 'документы',
      },
    };
    for (final MapEntry(key: name, value: names) in broken.entries) {
      test(name, () {
        expect(() => Settings(layoutFolderNames: names), throwsArgumentError);
      });
    }

    test('the names are copied and cannot be changed', () {
      final names = {...russianFolderNames};
      final settings = Settings(layoutFolderNames: names);
      names[Category.music] = 'Другое';
      expect(settings.layoutFolderNames![Category.music], 'Музыка');
      expect(
        () => settings.layoutFolderNames![Category.music] = 'x',
        throwsUnsupportedError,
      );
    });
  });

  test('an empty language tag is rejected: null means the system', () {
    expect(() => Settings(uiLocale: ''), throwsArgumentError);
  });

  test('copyWith changes only what is given; the language can be reset', () {
    final settings = Settings(
      layoutFolderNames: russianFolderNames,
      uiLocale: 'ru',
    );
    expect(settings.copyWith(), settings);
    expect(
      settings.copyWith(quarantineRetention: const Duration(days: 9)),
      Settings(
        quarantineRetention: const Duration(days: 9),
        layoutFolderNames: russianFolderNames,
        uiLocale: 'ru',
      ),
    );
    expect(settings.copyWith(uiLocale: () => null).uiLocale, isNull);
    expect(settings.copyWith(uiLocale: () => 'en').uiLocale, 'en');
  });
}
