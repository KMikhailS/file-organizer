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

  /// Startup error screen.
  ///
  /// In en, this message translates to:
  /// **'The app could not start'**
  String get startupFailedTitle;

  /// Technical reason of the startup error.
  ///
  /// In en, this message translates to:
  /// **'Details: {reason}'**
  String startupFailedDetails(String reason);

  /// Retries the start.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Next onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Onboarding: first page title.
  ///
  /// In en, this message translates to:
  /// **'Order in your files'**
  String get introTitle;

  /// Onboarding: what the app does.
  ///
  /// In en, this message translates to:
  /// **'The app finds duplicates and sorts files from Downloads, messengers and other cluttered places into folders.'**
  String get introText;

  /// Onboarding: safety point.
  ///
  /// In en, this message translates to:
  /// **'You see the plan first'**
  String get introPlanTitle;

  /// Onboarding: safety point.
  ///
  /// In en, this message translates to:
  /// **'Nothing changes until you look through the plan and apply it.'**
  String get introPlanText;

  /// Onboarding: safety point.
  ///
  /// In en, this message translates to:
  /// **'Nothing is deleted'**
  String get introQuarantineTitle;

  /// Onboarding: safety point.
  ///
  /// In en, this message translates to:
  /// **'Extra copies go to a quarantine folder and can be brought back.'**
  String get introQuarantineText;

  /// Onboarding: safety point.
  ///
  /// In en, this message translates to:
  /// **'Everything can be undone'**
  String get introUndoTitle;

  /// Onboarding: safety point.
  ///
  /// In en, this message translates to:
  /// **'Undo puts every file back where it was.'**
  String get introUndoText;

  /// Onboarding: access step title.
  ///
  /// In en, this message translates to:
  /// **'Access to your files'**
  String get accessTitle;

  /// Onboarding: why the access is needed.
  ///
  /// In en, this message translates to:
  /// **'To find duplicates and sort files, the app needs \"All files access\". Android opens its settings: turn the switch on and come back.'**
  String get accessText;

  /// The user came back without granting the access.
  ///
  /// In en, this message translates to:
  /// **'The access is not granted yet. Without it the app cannot look at your files.'**
  String get accessNotGranted;

  /// Onboarding: notifications step title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Onboarding: why notifications.
  ///
  /// In en, this message translates to:
  /// **'A cleanup goes on when you leave the app. A notification shows how far it is.'**
  String get notificationsText;

  /// Asks for the notification permission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// The user did not allow notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. A cleanup still runs, but its progress is not shown outside the app.'**
  String get notificationsDenied;

  /// Skips the notifications step.
  ///
  /// In en, this message translates to:
  /// **'Continue without them'**
  String get continueWithoutNotifications;

  /// Label of a folder name field: what goes there.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// Label of a folder name field.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get categoryPhotos;

  /// Label of a folder name field.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get categoryVideos;

  /// Label of a folder name field.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get categoryScreenshots;

  /// Label of a folder name field.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryMusic;

  /// Label of a folder name field.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get categoryArchives;

  /// Label of a folder name field.
  ///
  /// In en, this message translates to:
  /// **'Installers (APK)'**
  String get categoryInstallers;

  /// Label of a folder name field.
  ///
  /// In en, this message translates to:
  /// **'Other files'**
  String get categoryOther;

  /// Folder name check.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get folderNameEmpty;

  /// Folder name check.
  ///
  /// In en, this message translates to:
  /// **'At most {max} characters'**
  String folderNameTooLong(int max);

  /// Folder name check; characters is a list like / \ : *.
  ///
  /// In en, this message translates to:
  /// **'A name cannot contain {characters}'**
  String folderNameForbidden(String characters);

  /// Folder name check.
  ///
  /// In en, this message translates to:
  /// **'A name cannot start with a dot'**
  String get folderNameLeadingDot;

  /// Folder name check.
  ///
  /// In en, this message translates to:
  /// **'This name is already used'**
  String get folderNameDuplicate;

  /// The main button.
  ///
  /// In en, this message translates to:
  /// **'Tidy up'**
  String get cleanUpButton;

  /// Home: the access was taken back.
  ///
  /// In en, this message translates to:
  /// **'No access to your files'**
  String get accessRevokedTitle;

  /// Home: the access was taken back.
  ///
  /// In en, this message translates to:
  /// **'Grant the access again to tidy up.'**
  String get accessRevokedText;

  /// Home: no finished sessions.
  ///
  /// In en, this message translates to:
  /// **'No cleanups yet'**
  String get lastCleanupNone;

  /// Home: date of the last cleanup.
  ///
  /// In en, this message translates to:
  /// **'Last cleanup: {date}'**
  String lastCleanupTitle(String date);

  /// Status of a cleanup.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sessionCompleted;

  /// Status of a cleanup.
  ///
  /// In en, this message translates to:
  /// **'Finished with errors'**
  String get sessionFailed;

  /// Status of a cleanup.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get sessionCancelled;

  /// Status of a cleanup.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get sessionReverted;

  /// Status of a cleanup.
  ///
  /// In en, this message translates to:
  /// **'Partly undone'**
  String get sessionPartiallyReverted;

  /// Home: counts of the last cleanup.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} operations done'**
  String lastCleanupDone(int done, int total);

  /// Home: problems of the last cleanup.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 operation skipped or failed} other{{count} operations skipped or failed}}'**
  String lastCleanupProblems(int count);

  /// Home: undone operations of the last cleanup.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 operation undone} other{{count} operations undone}}'**
  String lastCleanupReverted(int count);

  /// Home: space freed by the last cleanup.
  ///
  /// In en, this message translates to:
  /// **'Freed: {size}'**
  String lastCleanupFreed(String size);

  /// Stops the running work; also the action of the notification.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Shown after Cancel until the work stops.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get cancelling;

  /// Goes back to the home screen.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Progress screen hint.
  ///
  /// In en, this message translates to:
  /// **'You can leave the app: the work goes on.'**
  String get progressCanLeave;

  /// Which source is scanned.
  ///
  /// In en, this message translates to:
  /// **'Storage {index} of {count}'**
  String progressStorageOf(int index, int count);

  /// The pipeline failed.
  ///
  /// In en, this message translates to:
  /// **'Could not make a plan'**
  String get planFailedTitle;

  /// Plan screen title.
  ///
  /// In en, this message translates to:
  /// **'Cleanup plan'**
  String get planTitle;

  /// Plan summary: approved files.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file will be tidied up} other{{count} files will be tidied up}}'**
  String planSummaryFiles(int count);

  /// Plan summary: bytes freed by approved duplicates.
  ///
  /// In en, this message translates to:
  /// **'{size} will be freed'**
  String planSummaryFreed(String size);

  /// No operation approved.
  ///
  /// In en, this message translates to:
  /// **'Nothing is selected'**
  String get planNothingSelected;

  /// Empty plan.
  ///
  /// In en, this message translates to:
  /// **'Everything is in order'**
  String get planEmptyTitle;

  /// Empty plan.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to tidy up right now.'**
  String get planEmptyText;

  /// Plan group of duplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Duplicates: 1 file, {size}} other{Duplicates: {count} files, {size}}}'**
  String groupDuplicates(int count, String size);

  /// Plan group of moves; folder like 'Photos / 2024'.
  ///
  /// In en, this message translates to:
  /// **'To {folder}: {count}'**
  String groupMoveTo(String folder, int count);

  /// Explains the duplicates group.
  ///
  /// In en, this message translates to:
  /// **'Extra copies go to the quarantine; the copy that stays is named next to each.'**
  String get groupDuplicatesHint;

  /// Where a file of the plan lies now.
  ///
  /// In en, this message translates to:
  /// **'From {folder}'**
  String fileFrom(String folder);

  /// Executes the approved plan.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// Declines the plan.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// Expands a plan group.
  ///
  /// In en, this message translates to:
  /// **'Show files'**
  String get showFiles;

  /// Collapses a plan group.
  ///
  /// In en, this message translates to:
  /// **'Hide files'**
  String get hideFiles;

  /// Files the rules could not classify.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Not sorted: 1 file} other{Not sorted: {count} files}}'**
  String unresolvedTitle(int count);

  /// Explains unresolved files.
  ///
  /// In en, this message translates to:
  /// **'The app is not sure where these files belong. They stay where they are.'**
  String get unresolvedText;

  /// Duplicates outside cluttered places.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more copy is in your own folders: it stays untouched} other{{count} more copies are in your own folders: they stay untouched}}'**
  String untouchedCopies(int count);

  /// Plan warnings.
  ///
  /// In en, this message translates to:
  /// **'Not everything could be checked'**
  String get warningsTitle;

  /// Plan warning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder could not be read} other{{count} folders could not be read}}'**
  String warningInaccessible(int count);

  /// Plan warning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file could not be read: its duplicates are unknown} other{{count} files could not be read: their duplicates are unknown}}'**
  String warningUnhashed(int count);

  /// Plan warning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 storage was not available} other{{count} storages were not available}}'**
  String warningUnavailableSources(int count);

  /// Result title.
  ///
  /// In en, this message translates to:
  /// **'Cleanup done'**
  String get resultCompleted;

  /// Result title.
  ///
  /// In en, this message translates to:
  /// **'Cleanup stopped'**
  String get resultCancelled;

  /// Result title: every operation that could be undone was undone (a lost file still shows among the problems).
  ///
  /// In en, this message translates to:
  /// **'Cleanup undone'**
  String get resultReverted;

  /// Result title.
  ///
  /// In en, this message translates to:
  /// **'Cleanup partly undone'**
  String get resultPartiallyReverted;

  /// Result count.
  ///
  /// In en, this message translates to:
  /// **'Done: {count}'**
  String countDone(int count);

  /// Result count.
  ///
  /// In en, this message translates to:
  /// **'Skipped: {count}'**
  String countSkipped(int count);

  /// Result count.
  ///
  /// In en, this message translates to:
  /// **'Failed: {count}'**
  String countFailed(int count);

  /// Result count.
  ///
  /// In en, this message translates to:
  /// **'Brought back: {count}'**
  String countReverted(int count);

  /// Result count.
  ///
  /// In en, this message translates to:
  /// **'Not brought back: {count}'**
  String countNotReverted(int count);

  /// Problems list title.
  ///
  /// In en, this message translates to:
  /// **'What did not work'**
  String get problemsTitle;

  /// Marks a problem recovery could not sort out.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// Undoes the cleanup just done.
  ///
  /// In en, this message translates to:
  /// **'Undo the cleanup'**
  String get undoCleanupButton;

  /// Closes a result.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Undo confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Bring the files back?'**
  String get undoConfirmTitle;

  /// Undo confirmation text.
  ///
  /// In en, this message translates to:
  /// **'Every file of this cleanup goes back where it was.'**
  String get undoConfirmAll;

  /// Undo confirmation text.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file goes back where it was.} other{{count} files go back where they were.}}'**
  String undoConfirmFiles(int count);

  /// Confirms an undo.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get undoConfirmYes;

  /// Interrupted cleanup title.
  ///
  /// In en, this message translates to:
  /// **'The last cleanup was interrupted'**
  String get interruptedTitle;

  /// Interrupted cleanup explanation.
  ///
  /// In en, this message translates to:
  /// **'The app stopped in the middle of a cleanup. Every operation in progress was checked: what was done stays done, nothing was overwritten.'**
  String get interruptedText;

  /// Interrupted cleanup count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 operation sorted out} other{{count} operations sorted out}}'**
  String interruptedOperations(int count);

  /// Interrupted sessions of an unavailable storage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cleanup waits for its storage to come back} other{{count} cleanups wait for their storage to come back}}'**
  String interruptedUnavailable(int count);

  /// Plans what is left.
  ///
  /// In en, this message translates to:
  /// **'Finish the cleanup'**
  String get interruptedFinish;

  /// Undoes the interrupted cleanup.
  ///
  /// In en, this message translates to:
  /// **'Undo it'**
  String get interruptedUndo;

  /// Leaves the decision for later.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get interruptedLater;

  /// History screen title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Status of a session whose storage was not available for recovery.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get sessionInterrupted;

  /// Session screen title.
  ///
  /// In en, this message translates to:
  /// **'Cleanup of {date}'**
  String sessionTitle(String date);

  /// Undoes a past session.
  ///
  /// In en, this message translates to:
  /// **'Undo the whole cleanup'**
  String get undoWholeButton;

  /// Undoes one group of a past session.
  ///
  /// In en, this message translates to:
  /// **'Bring this group back'**
  String get undoGroupButton;

  /// Undoes one file of a past session.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get undoFileButton;

  /// A file whose quarantine copy was purged.
  ///
  /// In en, this message translates to:
  /// **'Quarantine emptied: cannot be brought back'**
  String get purgedMark;

  /// History file status.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fileDone;

  /// History file status.
  ///
  /// In en, this message translates to:
  /// **'Brought back'**
  String get fileReverted;

  /// A past session with nothing to undo.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to undo'**
  String get nothingToUndo;

  /// History group size.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String groupFiles(int count);

  /// History group of duplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get groupDuplicatesTitle;

  /// History group of moves.
  ///
  /// In en, this message translates to:
  /// **'To {folder}'**
  String groupMoveTitle(String folder);

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get sectionFolders;

  /// Settings section hint.
  ///
  /// In en, this message translates to:
  /// **'Mark a folder to change what the cleanup does with it.'**
  String get foldersHint;

  /// Zone mark.
  ///
  /// In en, this message translates to:
  /// **'Tidy up'**
  String get zoneChaos;

  /// Zone mark.
  ///
  /// In en, this message translates to:
  /// **'Leave alone'**
  String get zoneOrganized;

  /// Zone mark.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get zoneExcluded;

  /// Zone mark hint.
  ///
  /// In en, this message translates to:
  /// **'Its files are sorted into the template folders'**
  String get zoneChaosHint;

  /// Zone mark hint.
  ///
  /// In en, this message translates to:
  /// **'Its files are never moved'**
  String get zoneOrganizedHint;

  /// Zone mark hint.
  ///
  /// In en, this message translates to:
  /// **'Not even looked at'**
  String get zoneExcludedHint;

  /// Adds a zone mark.
  ///
  /// In en, this message translates to:
  /// **'Mark a folder'**
  String get addFolderMark;

  /// No zone marks.
  ///
  /// In en, this message translates to:
  /// **'No marks yet'**
  String get noFolderMarks;

  /// Zone choice dialog.
  ///
  /// In en, this message translates to:
  /// **'What to do with {folder}?'**
  String chooseZoneTitle(String folder);

  /// Warning before a 'tidy up' mark.
  ///
  /// In en, this message translates to:
  /// **'Every file in {folder} and its subfolders will be offered for sorting into the template folders. Nothing moves until you apply a plan.'**
  String chaosWarning(String folder);

  /// Goes on after a warning.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Removes a zone mark.
  ///
  /// In en, this message translates to:
  /// **'Remove the mark'**
  String get removeMark;

  /// The root of the storage as a folder.
  ///
  /// In en, this message translates to:
  /// **'The whole storage'**
  String get storageRoot;

  /// Folder picker title.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get chooseFolderTitle;

  /// Picks the folder shown.
  ///
  /// In en, this message translates to:
  /// **'Choose this folder'**
  String get chooseThisFolder;

  /// Folder picker: empty.
  ///
  /// In en, this message translates to:
  /// **'No folders inside'**
  String get noSubfolders;

  /// Folder picker: error.
  ///
  /// In en, this message translates to:
  /// **'This folder cannot be read'**
  String get folderUnreadable;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Your rules'**
  String get sectionRules;

  /// Settings section hint.
  ///
  /// In en, this message translates to:
  /// **'Your rules apply before the built-in ones, from the top.'**
  String get rulesHint;

  /// Adds a rule.
  ///
  /// In en, this message translates to:
  /// **'Add a rule'**
  String get addRule;

  /// No rules.
  ///
  /// In en, this message translates to:
  /// **'No rules yet'**
  String get noRules;

  /// Rule editor title.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get ruleTitle;

  /// Rule field.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get ruleExtensions;

  /// Rule field hint.
  ///
  /// In en, this message translates to:
  /// **'pdf, docx'**
  String get ruleExtensionsHint;

  /// Rule field.
  ///
  /// In en, this message translates to:
  /// **'Name contains'**
  String get ruleNameContains;

  /// Rule field.
  ///
  /// In en, this message translates to:
  /// **'In folder'**
  String get ruleFolder;

  /// Rule without a folder.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get ruleAnyFolder;

  /// Rule field.
  ///
  /// In en, this message translates to:
  /// **'Put into'**
  String get ruleTarget;

  /// Rule target: unresolved.
  ///
  /// In en, this message translates to:
  /// **'Leave where it is'**
  String get ruleKeepInPlace;

  /// Rule validation.
  ///
  /// In en, this message translates to:
  /// **'Set at least one condition'**
  String get ruleNeedsCondition;

  /// Saves.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Deletes a rule.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Moves a rule up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// Moves a rule down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// Rule summary part.
  ///
  /// In en, this message translates to:
  /// **'name contains «{text}»'**
  String ruleSummaryName(String text);

  /// Rule summary part.
  ///
  /// In en, this message translates to:
  /// **'in {folder}'**
  String ruleSummaryFolder(String folder);

  /// Rule summary.
  ///
  /// In en, this message translates to:
  /// **'{conditions} → {target}'**
  String ruleSummary(String conditions, String target);

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Quarantine'**
  String get sectionQuarantine;

  /// Settings section hint.
  ///
  /// In en, this message translates to:
  /// **'Extra copies are kept for a while, so that a cleanup can be undone, then deleted for good.'**
  String get quarantineHint;

  /// Quarantine retention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String retentionDays(int count);

  /// Warning before a shorter retention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copies older than 1 day are deleted for good on the next start of the app; they cannot be brought back.} other{Copies older than {count} days are deleted for good on the next start of the app; they cannot be brought back.}}'**
  String retentionShorterWarning(int count);

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// UI language: the system's.
  ///
  /// In en, this message translates to:
  /// **'As on the phone'**
  String get languageSystem;

  /// Russian, in Russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// English, in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get sectionPermissions;

  /// Permission name.
  ///
  /// In en, this message translates to:
  /// **'All files access'**
  String get permissionAllFiles;

  /// Permission state.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionGranted;

  /// Permission state.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get permissionNotGranted;

  /// Notification permission state.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notificationsOn;

  /// Notification permission state.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationsOff;

  /// Shown when the user marks a template folder or a folder inside one.
  ///
  /// In en, this message translates to:
  /// **'This is a folder of the template: the cleanup never moves anything in it, so a mark has no effect here.'**
  String get templateFolderNote;
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
