import 'package:file_organizer/core/model/category.dart';

/// Texts the state layer needs before localization exists.
///
/// TEMPORARY (stage 2, task 10): task 11 replaces them with the ARB files
/// (ru / en) and the folder names the user confirms on first launch.
abstract final class AppTexts {
  /// Names of the template folders.
  static const Map<Category, String> folderNames = {
    Category.documents: 'Documents',
    Category.photos: 'Photos',
    Category.videos: 'Videos',
    Category.screenshots: 'Screenshots',
    Category.music: 'Music',
    Category.archives: 'Archives',
    Category.installers: 'Installers',
    Category.other: 'Other',
  };

  /// The label of a file that undo brings back next to a taken name.
  static const String restoredLabel = 'restored';

  /// The name of the shared storage source.
  static const String internalStorage = 'Internal storage';

  /// The notification channel of the foreground service.
  static const String channelName = 'Cleanup progress';

  static const String scanning = 'Looking at your files';
  static const String analyzing = 'Looking for duplicates';
  static const String executing = 'Tidying up';
  static const String undoing = 'Undoing the cleanup';

  static String filesSeen(int count) => '$count files';

  static String stepOf(int done, int total) => '$done of $total';
}
