import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// The app name.
  ///
  /// In en, this message translates to:
  /// **'File Organizer'**
  String get appTitle;

  /// Template folder for documents. Fixed on the first start; one folder name, no slashes.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get folderDocuments;

  /// Template folder for photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get folderPhotos;

  /// Template folder for videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get folderVideos;

  /// Template folder for screenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get folderScreenshots;

  /// Template folder for music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get folderMusic;

  /// Template folder for archives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get folderArchives;

  /// Template folder for installers (APK).
  ///
  /// In en, this message translates to:
  /// **'Installers'**
  String get folderInstallers;

  /// Template folder for other known files.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get folderOther;

  /// Put into the name of a file that undo brings back next to a taken name: 'photo (restored).jpg'. No slashes.
  ///
  /// In en, this message translates to:
  /// **'restored'**
  String get restoredLabel;

  /// The shared storage of the phone.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get internalStorage;

  /// Name of the notification channel in the system settings.
  ///
  /// In en, this message translates to:
  /// **'Cleanup progress'**
  String get notificationChannel;

  /// Notification title while scanning.
  ///
  /// In en, this message translates to:
  /// **'Looking at your files'**
  String get progressScanning;

  /// Notification title while looking for duplicates.
  ///
  /// In en, this message translates to:
  /// **'Looking for duplicates'**
  String get progressAnalyzing;

  /// Notification title while the plan runs.
  ///
  /// In en, this message translates to:
  /// **'Tidying up'**
  String get progressExecuting;

  /// Notification title while undoing.
  ///
  /// In en, this message translates to:
  /// **'Undoing the cleanup'**
  String get progressUndoing;

  /// A number of files.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String filesCount(int count);

  /// Progress: done of total.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String stepOf(int done, int total);

  /// Why a file goes to the quarantine: it is a copy of the kept file.
  ///
  /// In en, this message translates to:
  /// **'Copy of {keeper}'**
  String reasonDuplicateOf(String keeper);

  /// Why a folder is created.
  ///
  /// In en, this message translates to:
  /// **'Needed for {folder}'**
  String reasonFolderFor(String folder);

  /// Why recovery puts an empty file into the quarantine.
  ///
  /// In en, this message translates to:
  /// **'Empty placeholder left by the interrupted move of {file}'**
  String reasonMovePlaceholder(String file);

  /// Why a file got its folder.
  ///
  /// In en, this message translates to:
  /// **'By your rule'**
  String get classifiedByUserRule;

  /// Why a file got its folder.
  ///
  /// In en, this message translates to:
  /// **'By extension .{extension}'**
  String classifiedByExtension(String extension);

  /// Why a file got its folder.
  ///
  /// In en, this message translates to:
  /// **'The name looks like a screenshot'**
  String get classifiedScreenshotName;

  /// Why a file got its folder.
  ///
  /// In en, this message translates to:
  /// **'Lies in a screenshots folder'**
  String get classifiedScreenshotFolder;

  /// Why a file got its folder.
  ///
  /// In en, this message translates to:
  /// **'Suggested by AI'**
  String get classifiedAiSuggestion;

  /// Why a file stays where it is.
  ///
  /// In en, this message translates to:
  /// **'Unknown extension .{extension}'**
  String unresolvedUnknownExtension(String extension);

  /// Why a file stays where it is.
  ///
  /// In en, this message translates to:
  /// **'No extension'**
  String get unresolvedNoExtension;

  /// Why a file stays where it is.
  ///
  /// In en, this message translates to:
  /// **'Named like a screenshot, but not an image (.{extension})'**
  String unresolvedScreenshotNameNotImage(String extension);

  /// Why a file stays where it is.
  ///
  /// In en, this message translates to:
  /// **'The content ({mimeType}) does not match the extension .{extension}'**
  String unresolvedMimeMismatch(String mimeType, String extension);

  /// A problem with another path than the file's own.
  ///
  /// In en, this message translates to:
  /// **'{problem}: {path}'**
  String problemAt(String problem, String path);

  /// Why an operation was skipped.
  ///
  /// In en, this message translates to:
  /// **'The file is gone'**
  String get problemFileGone;

  /// Why an operation was skipped.
  ///
  /// In en, this message translates to:
  /// **'This is no longer a file'**
  String get problemNotAFile;

  /// Why an operation was skipped.
  ///
  /// In en, this message translates to:
  /// **'The file has changed since the scan'**
  String get problemFileChanged;

  /// Why an operation was skipped.
  ///
  /// In en, this message translates to:
  /// **'This is no longer a duplicate'**
  String get problemNotADuplicate;

  /// Why an operation was skipped.
  ///
  /// In en, this message translates to:
  /// **'The kept copy {keeper} has changed or is gone'**
  String problemKeeperChanged(String keeper);

  /// Why an operation was skipped.
  ///
  /// In en, this message translates to:
  /// **'The folder {folder} could not be created'**
  String problemDependsOnMissingFolder(String folder);

  /// Why a folder was not created.
  ///
  /// In en, this message translates to:
  /// **'The folder already exists'**
  String get problemFolderExists;

  /// Why undo left a folder.
  ///
  /// In en, this message translates to:
  /// **'The folder is not empty'**
  String get problemFolderNotEmpty;

  /// Why undo skipped a file.
  ///
  /// In en, this message translates to:
  /// **'The file is no longer where the cleanup put it'**
  String get problemNotWhereCleanupPutIt;

  /// Why undo skipped a file.
  ///
  /// In en, this message translates to:
  /// **'The quarantine was emptied: the file cannot come back'**
  String get problemQuarantinePurged;

  /// Why undo skipped a file.
  ///
  /// In en, this message translates to:
  /// **'The file cannot be brought back from the quarantine'**
  String get problemCannotRestore;

  /// Why undo skipped a file.
  ///
  /// In en, this message translates to:
  /// **'{folder} is a file now, not a folder'**
  String problemFolderReplacedByFile(String folder);

  /// Why undo skipped a file.
  ///
  /// In en, this message translates to:
  /// **'{original} and every \"restored\" name next to it are taken'**
  String problemNoFreeName(String original);

  /// Why an operation did not run.
  ///
  /// In en, this message translates to:
  /// **'Interrupted before it took effect'**
  String get problemInterrupted;

  /// Recovery could not sort out an operation.
  ///
  /// In en, this message translates to:
  /// **'Needs attention: {cause}'**
  String problemNeedsAttention(String cause);

  /// Recovery could not sort out an operation; error is the file error behind it.
  ///
  /// In en, this message translates to:
  /// **'Needs attention: {cause} ({error})'**
  String problemNeedsAttentionBecause(String cause, String error);

  /// Cause of 'needs attention'.
  ///
  /// In en, this message translates to:
  /// **'the file is neither at its old nor at its new place'**
  String get attentionFileLost;

  /// Cause of 'needs attention'.
  ///
  /// In en, this message translates to:
  /// **'the file could not be checked'**
  String get attentionCannotCheck;

  /// Cause of 'needs attention'.
  ///
  /// In en, this message translates to:
  /// **'the quarantine could not be searched'**
  String get attentionCannotSearchQuarantine;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get fileErrorNotFound;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'The name is already taken'**
  String get fileErrorTargetExists;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get fileErrorPermissionDenied;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'In use by another app'**
  String get fileErrorLocked;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'The storage does not allow this'**
  String get fileErrorUnsupported;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'The folder is not empty'**
  String get fileErrorNotEmpty;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'A file where a folder was expected, or the other way round'**
  String get fileErrorWrongType;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get fileErrorCancelled;

  /// A file system error.
  ///
  /// In en, this message translates to:
  /// **'Read or write error'**
  String get fileErrorIoError;

  /// A size in bytes; size is already formatted.
  ///
  /// In en, this message translates to:
  /// **'{size} B'**
  String sizeBytes(String size);

  /// A size in kilobytes (1000 bytes).
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String sizeKilobytes(String size);

  /// A size in megabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMegabytes(String size);

  /// A size in gigabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} GB'**
  String sizeGigabytes(String size);

  /// A size in terabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} TB'**
  String sizeTerabytes(String size);

  /// Shown while the access is not granted.
  ///
  /// In en, this message translates to:
  /// **'The app needs \"All files access\" to look at your files.'**
  String get accessNeeded;

  /// Opens the system access screen.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get grantAccess;

  /// Title of the folder names confirmation.
  ///
  /// In en, this message translates to:
  /// **'Folders for your files'**
  String get folderNamesTitle;

  /// Explains the folder names before they are fixed.
  ///
  /// In en, this message translates to:
  /// **'The cleanup sorts files into these folders at the top of the storage. Their names stay the same even if you change the language later.'**
  String get folderNamesExplanation;

  /// Fixes the folder names.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get folderNamesConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
