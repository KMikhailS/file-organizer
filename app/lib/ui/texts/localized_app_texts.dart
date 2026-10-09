import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/app_texts.dart';
import 'package:flutter/widgets.dart';

/// The texts of the state layer from the app's localization.
final class LocalizedAppTexts implements AppTexts {
  LocalizedAppTexts(this._l);

  /// The texts for the most preferred of [languages] (BCP 47 tags) that
  /// the app has; English if it has none of them. Picks the language the
  /// same way as `MaterialApp`.
  factory LocalizedAppTexts.forLanguages(List<String> languages) =>
      LocalizedAppTexts(lookupAppLocalizations(resolveLanguage(languages)));

  final AppLocalizations _l;

  @override
  Map<Category, String> get folderNames => {
    Category.documents: _l.folderDocuments,
    Category.photos: _l.folderPhotos,
    Category.videos: _l.folderVideos,
    Category.screenshots: _l.folderScreenshots,
    Category.music: _l.folderMusic,
    Category.archives: _l.folderArchives,
    Category.installers: _l.folderInstallers,
    Category.other: _l.folderOther,
  };

  @override
  String get restoredLabel => _l.restoredLabel;

  @override
  String get channelName => _l.notificationChannel;

  @override
  String get scanning => _l.progressScanning;

  @override
  String get analyzing => _l.progressAnalyzing;

  @override
  String get executing => _l.progressExecuting;

  @override
  String get undoing => _l.progressUndoing;

  @override
  String filesSeen(int count) => _l.filesCount(count);

  @override
  String stepOf(int done, int total) => _l.stepOf(done, total);
}

/// The supported locale for [languages] (BCP 47 tags, most preferred
/// first), resolved like `MaterialApp` does without a resolution callback.
Locale resolveLanguage(List<String> languages) => basicLocaleListResolution(
  languages.map(localeOfTag).toList(),
  AppLocalizations.supportedLocales,
);

/// The [Locale] of a BCP 47 tag (`ru`, `ru-RU`, `zh-Hans-CN`); extensions
/// are ignored.
Locale localeOfTag(String tag) {
  final parts = tag.split(RegExp('[-_]'));
  String? script;
  String? country;
  for (final part in parts.skip(1)) {
    if (script == null && country == null && part.length == 4) {
      script = part;
    } else if (country == null &&
        (part.length == 2 || RegExp(r'^\d{3}$').hasMatch(part))) {
      country = part.toUpperCase();
    }
  }
  return Locale.fromSubtags(
    languageCode: parts.first.toLowerCase(),
    scriptCode: script,
    countryCode: country,
  );
}

/// The BCP 47 tags of [locales].
List<String> tagsOf(List<Locale> locales) => [
  for (final locale in locales) locale.toLanguageTag(),
];
