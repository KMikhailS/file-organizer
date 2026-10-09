import 'package:file_organizer/core/model/file_error_kind.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/texts/path_text.dart';

/// Why an operation failed, was skipped or could not be undone, in the
/// user's language. Technical details of the adapter are never shown.
String operationProblemText(AppLocalizations l, OperationProblem problem) =>
    switch (problem) {
      FileSystemError(:final kind, :final path) =>
        path == null
            ? fileErrorText(l, kind)
            : l.problemAt(fileErrorText(l, kind), pathText(path)),
      FileGone() => l.problemFileGone,
      NotAFile() => l.problemNotAFile,
      FileChanged() => l.problemFileChanged,
      NotADuplicate() => l.problemNotADuplicate,
      KeeperChanged(:final keeper) => l.problemKeeperChanged(pathText(keeper)),
      DependsOnMissingFolder(:final folder) => l.problemDependsOnMissingFolder(
        pathText(folder),
      ),
      FolderExists() => l.problemFolderExists,
      FolderNotEmpty() => l.problemFolderNotEmpty,
      NotWhereCleanupPutIt() => l.problemNotWhereCleanupPutIt,
      QuarantinePurged() => l.problemQuarantinePurged,
      CannotRestore() => l.problemCannotRestore,
      FolderReplacedByFile(:final folder) => l.problemFolderReplacedByFile(
        pathText(folder),
      ),
      NoFreeName(:final original) => l.problemNoFreeName(pathText(original)),
      InterruptedOperation() => l.problemInterrupted,
      NeedsAttention(:final cause, :final errorKind) =>
        errorKind == null
            ? l.problemNeedsAttention(attentionCauseText(l, cause))
            : l.problemNeedsAttentionBecause(
                attentionCauseText(l, cause),
                fileErrorText(l, errorKind),
              ),
      // Written before problems had codes (database version 1).
      LegacyProblem(:final text) => text,
    };

/// A file system error in the user's language.
String fileErrorText(AppLocalizations l, FileErrorKind kind) => switch (kind) {
  FileErrorKind.notFound => l.fileErrorNotFound,
  FileErrorKind.targetExists => l.fileErrorTargetExists,
  FileErrorKind.permissionDenied => l.fileErrorPermissionDenied,
  FileErrorKind.locked => l.fileErrorLocked,
  FileErrorKind.unsupported => l.fileErrorUnsupported,
  FileErrorKind.notEmpty => l.fileErrorNotEmpty,
  FileErrorKind.wrongType => l.fileErrorWrongType,
  FileErrorKind.cancelled => l.fileErrorCancelled,
  FileErrorKind.ioError => l.fileErrorIoError,
};

/// What recovery could not sort out, in the user's language.
String attentionCauseText(AppLocalizations l, AttentionCause cause) =>
    switch (cause) {
      AttentionCause.fileLost => l.attentionFileLost,
      AttentionCause.cannotCheck => l.attentionCannotCheck,
      AttentionCause.cannotSearchQuarantine =>
        l.attentionCannotSearchQuarantine,
    };
