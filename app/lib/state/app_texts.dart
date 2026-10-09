import 'package:file_organizer/core/model/category.dart';

/// The texts the state layer hands to the core and the platform: the
/// template folders proposed on the first start, the "restored" label of
/// undo and the notification of the foreground service.
///
/// The state layer has no localization of its own (`docs/stage2_android.md`,
/// section 11): the UI implements this from its ARB files, and
/// `appTextsFactoryProvider` (`providers.dart`) picks the language.
abstract interface class AppTexts {
  /// Names of the template folders proposed on the first start.
  Map<Category, String> get folderNames;

  /// The label of a file that undo brings back next to a taken name.
  String get restoredLabel;

  /// The notification channel of the foreground service.
  String get channelName;

  String get scanning;
  String get analyzing;
  String get executing;
  String get undoing;

  String filesSeen(int count);

  String stepOf(int done, int total);
}

/// Makes the texts for the languages the user prefers, most preferred
/// first, as BCP 47 tags (`ru-RU`, `en`). Falls back to a language the app
/// has.
typedef AppTextsFactory = AppTexts Function(List<String> languages);
