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
  String get sessionReverted => 'Undone';

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

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelling => 'Cancelling…';

  @override
  String get back => 'Back';

  @override
  String get progressCanLeave => 'You can leave the app: the work goes on.';

  @override
  String progressStorageOf(int index, int count) {
    return 'Storage $index of $count';
  }

  @override
  String get planFailedTitle => 'Could not make a plan';

  @override
  String get planTitle => 'Cleanup plan';

  @override
  String planSummaryFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files will be tidied up',
      one: '1 file will be tidied up',
    );
    return '$_temp0';
  }

  @override
  String planSummaryFreed(String size) {
    return '$size will be freed';
  }

  @override
  String get planNothingSelected => 'Nothing is selected';

  @override
  String get planEmptyTitle => 'Everything is in order';

  @override
  String get planEmptyText => 'There is nothing to tidy up right now.';

  @override
  String groupDuplicates(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Duplicates: $count files, $size',
      one: 'Duplicates: 1 file, $size',
    );
    return '$_temp0';
  }

  @override
  String groupMoveTo(String folder, int count) {
    return 'To $folder: $count';
  }

  @override
  String get groupDuplicatesHint =>
      'Extra copies go to the quarantine; the copy that stays is named next to each.';

  @override
  String fileFrom(String folder) {
    return 'From $folder';
  }

  @override
  String get applyButton => 'Apply';

  @override
  String get declineButton => 'Decline';

  @override
  String get showFiles => 'Show files';

  @override
  String get hideFiles => 'Hide files';

  @override
  String unresolvedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Not sorted: $count files',
      one: 'Not sorted: 1 file',
    );
    return '$_temp0';
  }

  @override
  String get unresolvedText =>
      'The app is not sure where these files belong. They stay where they are.';

  @override
  String untouchedCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more copies are in your own folders: they stay untouched',
      one: '1 more copy is in your own folders: it stays untouched',
    );
    return '$_temp0';
  }

  @override
  String get warningsTitle => 'Not everything could be checked';

  @override
  String warningInaccessible(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders could not be read',
      one: '1 folder could not be read',
    );
    return '$_temp0';
  }

  @override
  String warningUnhashed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files could not be read: their duplicates are unknown',
      one: '1 file could not be read: its duplicates are unknown',
    );
    return '$_temp0';
  }

  @override
  String warningUnavailableSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count storages were not available',
      one: '1 storage was not available',
    );
    return '$_temp0';
  }

  @override
  String get resultCompleted => 'Cleanup done';

  @override
  String get resultCancelled => 'Cleanup stopped';

  @override
  String get resultReverted => 'Cleanup undone';

  @override
  String get resultPartiallyReverted => 'Cleanup partly undone';

  @override
  String countDone(int count) {
    return 'Done: $count';
  }

  @override
  String countSkipped(int count) {
    return 'Skipped: $count';
  }

  @override
  String countFailed(int count) {
    return 'Failed: $count';
  }

  @override
  String countReverted(int count) {
    return 'Brought back: $count';
  }

  @override
  String countNotReverted(int count) {
    return 'Not brought back: $count';
  }

  @override
  String get problemsTitle => 'What did not work';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get undoCleanupButton => 'Undo the cleanup';

  @override
  String get closeButton => 'Close';

  @override
  String get undoConfirmTitle => 'Bring the files back?';

  @override
  String get undoConfirmAll =>
      'Every file of this cleanup goes back where it was.';

  @override
  String undoConfirmFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files go back where they were.',
      one: '1 file goes back where it was.',
    );
    return '$_temp0';
  }

  @override
  String get undoConfirmYes => 'Bring back';

  @override
  String get interruptedTitle => 'The last cleanup was interrupted';

  @override
  String get interruptedText =>
      'The app stopped in the middle of a cleanup. Every operation in progress was checked: what was done stays done, nothing was overwritten.';

  @override
  String interruptedOperations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operations sorted out',
      one: '1 operation sorted out',
    );
    return '$_temp0';
  }

  @override
  String interruptedUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cleanups wait for their storage to come back',
      one: '1 cleanup waits for its storage to come back',
    );
    return '$_temp0';
  }

  @override
  String get interruptedFinish => 'Finish the cleanup';

  @override
  String get interruptedUndo => 'Undo it';

  @override
  String get interruptedLater => 'Not now';

  @override
  String get historyTitle => 'History';

  @override
  String get sessionInterrupted => 'Interrupted';

  @override
  String sessionTitle(String date) {
    return 'Cleanup of $date';
  }

  @override
  String get undoWholeButton => 'Undo the whole cleanup';

  @override
  String get undoGroupButton => 'Bring this group back';

  @override
  String get undoFileButton => 'Bring back';

  @override
  String get purgedMark => 'Quarantine emptied: cannot be brought back';

  @override
  String get fileDone => 'Done';

  @override
  String get fileReverted => 'Brought back';

  @override
  String get nothingToUndo => 'Nothing left to undo';

  @override
  String groupFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get groupDuplicatesTitle => 'Duplicates';

  @override
  String groupMoveTitle(String folder) {
    return 'To $folder';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionFolders => 'Folders';

  @override
  String get foldersHint =>
      'Mark a folder to change what the cleanup does with it.';

  @override
  String get zoneChaos => 'Tidy up';

  @override
  String get zoneOrganized => 'Leave alone';

  @override
  String get zoneExcluded => 'Exclude';

  @override
  String get zoneChaosHint => 'Its files are sorted into the template folders';

  @override
  String get zoneOrganizedHint => 'Its files are never moved';

  @override
  String get zoneExcludedHint => 'Not even looked at';

  @override
  String get addFolderMark => 'Mark a folder';

  @override
  String get noFolderMarks => 'No marks yet';

  @override
  String chooseZoneTitle(String folder) {
    return 'What to do with $folder?';
  }

  @override
  String chaosWarning(String folder) {
    return 'Every file in $folder and its subfolders will be offered for sorting into the template folders. Nothing moves until you apply a plan.';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get removeMark => 'Remove the mark';

  @override
  String get storageRoot => 'The whole storage';

  @override
  String get chooseFolderTitle => 'Choose a folder';

  @override
  String get chooseThisFolder => 'Choose this folder';

  @override
  String get noSubfolders => 'No folders inside';

  @override
  String get folderUnreadable => 'This folder cannot be read';

  @override
  String get sectionRules => 'Your rules';

  @override
  String get rulesHint =>
      'Your rules apply before the built-in ones, from the top.';

  @override
  String get addRule => 'Add a rule';

  @override
  String get noRules => 'No rules yet';

  @override
  String get ruleTitle => 'Rule';

  @override
  String get ruleExtensions => 'Extensions';

  @override
  String get ruleExtensionsHint => 'pdf, docx';

  @override
  String get ruleNameContains => 'Name contains';

  @override
  String get ruleFolder => 'In folder';

  @override
  String get ruleAnyFolder => 'Anywhere';

  @override
  String get ruleTarget => 'Put into';

  @override
  String get ruleKeepInPlace => 'Leave where it is';

  @override
  String get ruleNeedsCondition => 'Set at least one condition';

  @override
  String get saveButton => 'Save';

  @override
  String get deleteButton => 'Delete';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String ruleSummaryName(String text) {
    return 'name contains «$text»';
  }

  @override
  String ruleSummaryFolder(String folder) {
    return 'in $folder';
  }

  @override
  String ruleSummary(String conditions, String target) {
    return '$conditions → $target';
  }

  @override
  String get sectionQuarantine => 'Quarantine';

  @override
  String get quarantineHint =>
      'Extra copies are kept for a while, so that a cleanup can be undone, then deleted for good.';

  @override
  String retentionDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String retentionShorterWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Copies older than $count days are deleted for good on the next start of the app; they cannot be brought back.',
      one: 'Copies older than 1 day are deleted for good on the next start of the app; they cannot be brought back.',
    );
    return '$_temp0';
  }

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageSystem => 'As on the phone';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get sectionPermissions => 'Permissions';

  @override
  String get permissionAllFiles => 'All files access';

  @override
  String get permissionGranted => 'Granted';

  @override
  String get permissionNotGranted => 'Not granted';

  @override
  String get notificationsOn => 'On';

  @override
  String get notificationsOff => 'Off';

  @override
  String get templateFolderNote =>
      'This is a folder of the template: the cleanup never moves anything in it, so a mark has no effect here.';
}
