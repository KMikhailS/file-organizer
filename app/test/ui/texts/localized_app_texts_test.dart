import 'package:file_organizer/core/layout/layout.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/texts/localized_app_texts.dart';
import 'package:file_organizer/ui/texts/source_name.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/folder_names.dart';

void main() {
  group('the language', () {
    test('the first preferred language the app has; English otherwise', () {
      const cases = {
        <String>[]: 'en',
        ['ru-RU']: 'ru',
        ['ru']: 'ru',
        ['en-GB', 'ru']: 'en',
        ['de-DE', 'ru-RU']: 'ru',
        ['de-DE', 'fr']: 'en',
        ['uk-UA']: 'en',
      };
      for (final MapEntry(key: languages, value: expected) in cases.entries) {
        expect(
          resolveLanguage(languages).languageCode,
          expected,
          reason: '$languages',
        );
      }
    });

    test('BCP 47 tags become locales and back', () {
      expect(localeOfTag('ru-RU'), const Locale('ru', 'RU'));
      expect(localeOfTag('en_us'), const Locale('en', 'US'));
      expect(
        localeOfTag('zh-Hans-CN'),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      );
      expect(localeOfTag('es-419'), const Locale('es', '419'));
      expect(tagsOf(const [Locale('ru', 'RU'), Locale('en')]), ['ru-RU', 'en']);
    });
  });

  group('the texts of the state layer', () {
    final en = LocalizedAppTexts.forLanguages(const ['en']);
    final ru = LocalizedAppTexts.forLanguages(const ['ru']);

    test('the folder names the user approved', () {
      expect(en.folderNames, englishNames);
      expect(ru.folderNames, russianNames);
    });

    test('both sets of folder names make a valid template', () {
      for (final texts in [en, ru]) {
        expect(
          () => LayoutTemplate(folderNames: texts.folderNames),
          returnsNormally,
        );
        expect(
          () => Settings(layoutFolderNames: texts.folderNames),
          returnsNormally,
        );
      }
    });

    test('the "restored" label fits into a file name', () {
      expect(en.restoredLabel, 'restored');
      expect(ru.restoredLabel, 'восстановлено');
      for (final label in [en.restoredLabel, ru.restoredLabel]) {
        expect(label, isNot(contains('/')));
        expect(label.trim(), label);
      }
    });
  });

  test('the shared storage is named in the language of the screen', () {
    const storage = Source(
      id: SourceId('primary-storage'),
      kind: SourceKind.androidFullStorage,
      displayName: 'Internal storage',
      location: '/storage/emulated/0',
      capabilities: SourceCapabilities.none,
      enabled: true,
    );
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(sourceName(ru, storage), 'Внутреннее хранилище');
    const folder = Source(
      id: SourceId('f'),
      kind: SourceKind.desktopFolder,
      displayName: 'Мои файлы',
      location: '/home/user',
      capabilities: SourceCapabilities.none,
      enabled: true,
    );
    expect(sourceName(ru, folder), 'Мои файлы');
  });
}
