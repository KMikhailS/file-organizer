// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'File Organizer';

  @override
  String get folderDocuments => 'Documents';

  @override
  String get folderPhotos => 'Photos';

  @override
  String get folderVideos => 'Videos';

  @override
  String get folderScreenshots => 'Screenshots';

  @override
  String get folderMusic => 'Music';

  @override
  String get folderArchives => 'Archives';

  @override
  String get folderInstallers => 'Installers';

  @override
  String get folderOther => 'Other';

  @override
  String get restoredLabel => 'restored';

  @override
  String get internalStorage => 'Internal storage';

  @override
  String get notificationChannel => 'Cleanup progress';

  @override
  String get progressScanning => 'Looking at your files';

  @override
  String get progressAnalyzing => 'Looking for duplicates';

  @override
  String get progressExecuting => 'Tidying up';

  @override
  String get progressUndoing => 'Undoing the cleanup';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String stepOf(int done, int total) {
    return '$done of $total';
  }

  @override
  String reasonDuplicateOf(String keeper) {
    return 'Copy of $keeper';
  }

  @override
  String reasonFolderFor(String folder) {
    return 'Needed for $folder';
  }

  @override
  String reasonMovePlaceholder(String file) {
    return 'Empty placeholder left by the interrupted move of $file';
  }

  @override
  String get classifiedByUserRule => 'By your rule';

  @override
  String classifiedByExtension(String extension) {
    return 'By extension .$extension';
  }

  @override
  String get classifiedScreenshotName => 'The name looks like a screenshot';

  @override
  String get classifiedScreenshotFolder => 'Lies in a screenshots folder';

  @override
  String get classifiedAiSuggestion => 'Suggested by AI';

  @override
  String unresolvedUnknownExtension(String extension) {
    return 'Unknown extension .$extension';
  }

  @override
  String get unresolvedNoExtension => 'No extension';

  @override
  String unresolvedScreenshotNameNotImage(String extension) {
    return 'Named like a screenshot, but not an image (.$extension)';
  }

  @override
  String unresolvedMimeMismatch(String mimeType, String extension) {
    return 'The content ($mimeType) does not match the extension .$extension';
  }

  @override
  String problemAt(String problem, String path) {
    return '$problem: $path';
  }

  @override
  String get problemFileGone => 'The file is gone';

  @override
  String get problemNotAFile => 'This is no longer a file';

  @override
  String get problemFileChanged => 'The file has changed since the scan';

  @override
  String get problemNotADuplicate => 'This is no longer a duplicate';

  @override
  String problemKeeperChanged(String keeper) {
    return 'The kept copy $keeper has changed or is gone';
  }

  @override
  String problemDependsOnMissingFolder(String folder) {
    return 'The folder $folder could not be created';
  }

  @override
  String get problemFolderExists => 'The folder already exists';

  @override
  String get problemFolderNotEmpty => 'The folder is not empty';

  @override
  String get problemNotWhereCleanupPutIt =>
      'The file is no longer where the cleanup put it';

  @override
  String get problemQuarantinePurged =>
      'The quarantine was emptied: the file cannot come back';

  @override
  String get problemCannotRestore =>
      'The file cannot be brought back from the quarantine';

  @override
  String problemFolderReplacedByFile(String folder) {
    return '$folder is a file now, not a folder';
  }

  @override
  String problemNoFreeName(String original) {
    return '$original and every \"restored\" name next to it are taken';
  }

  @override
  String get problemInterrupted => 'Interrupted before it took effect';

  @override
  String problemNeedsAttention(String cause) {
    return 'Needs attention: $cause';
  }

  @override
  String problemNeedsAttentionBecause(String cause, String error) {
    return 'Needs attention: $cause ($error)';
  }

  @override
  String get attentionFileLost =>
      'the file is neither at its old nor at its new place';

  @override
  String get attentionCannotCheck => 'the file could not be checked';

  @override
  String get attentionCannotSearchQuarantine =>
      'the quarantine could not be searched';

  @override
  String get fileErrorNotFound => 'Not found';

  @override
  String get fileErrorTargetExists => 'The name is already taken';

  @override
  String get fileErrorPermissionDenied => 'No access';

  @override
  String get fileErrorLocked => 'In use by another app';

  @override
  String get fileErrorUnsupported => 'The storage does not allow this';

  @override
  String get fileErrorNotEmpty => 'The folder is not empty';

  @override
  String get fileErrorWrongType =>
      'A file where a folder was expected, or the other way round';

  @override
  String get fileErrorCancelled => 'Cancelled';

  @override
  String get fileErrorIoError => 'Read or write error';

  @override
  String sizeBytes(String size) {
    return '$size B';
  }

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String sizeGigabytes(String size) {
    return '$size GB';
  }

  @override
  String sizeTerabytes(String size) {
    return '$size TB';
  }

  @override
  String get grantAccess => 'Grant access';

  @override
  String get folderNamesTitle => 'Folders for your files';

  @override
  String get folderNamesExplanation =>
      'The cleanup sorts files into these folders at the top of the storage. Their names stay the same even if you change the language later.';

  @override
  String get folderNamesConfirm => 'Confirm';

  @override
  String get startupFailedTitle => 'The app could not start';

  @override
  String startupFailedDetails(String reason) {
    return 'Details: $reason';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get onboardingNext => 'Next';

  @override
  String get introTitle => 'Order in your files';

  @override
  String get introText =>
      'The app finds duplicates and sorts files from Downloads, messengers and other cluttered places into folders.';

  @override
  String get introPlanTitle => 'You see the plan first';

  @override
  String get introPlanText =>
      'Nothing changes until you look through the plan and apply it.';

  @override
  String get introQuarantineTitle => 'Nothing is deleted';

  @override
  String get introQuarantineText =>
      'Extra copies go to a quarantine folder and can be brought back.';

  @override
  String get introUndoTitle => 'Everything can be undone';

  @override
  String get introUndoText => 'Undo puts every file back where it was.';

  @override
  String get accessTitle => 'Access to your files';

  @override
  String get accessText =>
      'To find duplicates and sort files, the app needs \"All files access\". Android opens its settings: turn the switch on and come back.';

  @override
  String get accessNotGranted =>
      'The access is not granted yet. Without it the app cannot look at your files.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsText =>
      'A cleanup goes on when you leave the app. A notification shows how far it is.';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get notificationsDenied =>
      'Notifications are off. A cleanup still runs, but its progress is not shown outside the app.';

  @override
  String get continueWithoutNotifications => 'Continue without them';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryPhotos => 'Photos';

  @override
  String get categoryVideos => 'Videos';

  @override
  String get categoryScreenshots => 'Screenshots';

  @override
  String get categoryMusic => 'Music';

  @override
  String get categoryArchives => 'Archives';

  @override
  String get categoryInstallers => 'Installers (APK)';

  @override
  String get categoryOther => 'Other files';

  @override
  String get folderNameEmpty => 'Enter a name';

  @override
  String folderNameTooLong(int max) {
    return 'At most $max characters';
  }

  @override
  String folderNameForbidden(String characters) {
    return 'A name cannot contain $characters';
  }

  @override
  String get folderNameLeadingDot => 'A name cannot start with a dot';

  @override
  String get folderNameDuplicate => 'This name is already used';

  @override
  String get cleanUpButton => 'Tidy up';

  @override
  String get accessRevokedTitle => 'No access to your files';

  @override
  String get accessRevokedText => 'Grant the access again to tidy up.';

  @override
  String get lastCleanupNone => 'No cleanups yet';

  @override
  String lastCleanupTitle(String date) {
    return 'Last cleanup: $date';
  }

  @override
  String get sessionCompleted => 'Done';

  @override
  String get sessionFailed => 'Finished with errors';

  @override
  String get sessionCancelled => 'Stopped';

  @override
  String get sessionReverted => 'Undone: everything is back';

  @override
  String get sessionPartiallyReverted => 'Partly undone';

  @override
  String lastCleanupDone(int done, int total) {
    return '$done of $total operations done';
  }

  @override
  String lastCleanupProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operations skipped or failed',
      one: '1 operation skipped or failed',
    );
    return '$_temp0';
  }

  @override
  String lastCleanupReverted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operations undone',
      one: '1 operation undone',
    );
    return '$_temp0';
  }

  @override
  String lastCleanupFreed(String size) {
    return 'Freed: $size';
  }
}
