import 'package:file_organizer/core/model/file_error_kind.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:meta/meta.dart';

/// Why an operation failed, was skipped or could not be undone
/// (`Operation.error`): a code with parameters. The UI turns it into text
/// through localization.
@immutable
sealed class OperationProblem {
  const OperationProblem();
}

/// Problems without parameters: equal when they are of the same type.
sealed class _Plain extends OperationProblem {
  const _Plain();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

/// The file source failed (or a check through it failed).
final class FileSystemError extends OperationProblem {
  const FileSystemError(this.kind, {this.path, this.detail});

  final FileErrorKind kind;

  /// The path the failure is about when it is not the operation's own file
  /// (a kept copy, a folder on the way back).
  final LogicalPath? path;

  /// Technical details from the adapter, for logs; never shown as is.
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is FileSystemError &&
      other.kind == kind &&
      other.path == path &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(FileSystemError, kind, path, detail);

  @override
  String toString() =>
      'FileSystemError(${kind.name}'
      '${path == null ? '' : ', $path'}${detail == null ? '' : ': $detail'})';
}

/// The file is gone since the scan.
final class FileGone extends _Plain {
  const FileGone();
}

/// The path is no longer a file.
final class NotAFile extends _Plain {
  const NotAFile();
}

/// Size or modification date differ from what was recorded.
final class FileChanged extends _Plain {
  const FileChanged();
}

/// The copy is not (or no longer) a verified duplicate.
final class NotADuplicate extends _Plain {
  const NotADuplicate();
}

/// The kept copy of a duplicate group changed or is gone.
final class KeeperChanged extends OperationProblem {
  const KeeperChanged(this.keeper);

  /// Where the kept copy was expected.
  final LogicalPath keeper;

  @override
  bool operator ==(Object other) =>
      other is KeeperChanged && other.keeper == keeper;

  @override
  int get hashCode => Object.hash(KeeperChanged, keeper);

  @override
  String toString() => 'KeeperChanged($keeper)';
}

/// The target is inside a folder this session could not create.
final class DependsOnMissingFolder extends OperationProblem {
  const DependsOnMissingFolder(this.folder);

  final LogicalPath folder;

  @override
  bool operator ==(Object other) =>
      other is DependsOnMissingFolder && other.folder == folder;

  @override
  int get hashCode => Object.hash(DependsOnMissingFolder, folder);

  @override
  String toString() => 'DependsOnMissingFolder($folder)';
}

/// The folder to create already exists (appeared after planning).
final class FolderExists extends _Plain {
  const FolderExists();
}

/// Undo: a folder the cleanup created is not empty.
final class FolderNotEmpty extends _Plain {
  const FolderNotEmpty();
}

/// Undo: the moved file is not where the cleanup put it.
final class NotWhereCleanupPutIt extends _Plain {
  const NotWhereCleanupPutIt();
}

/// Undo: the quarantine object was purged; the file cannot come back.
final class QuarantinePurged extends _Plain {
  const QuarantinePurged();
}

/// Undo: the source cannot restore this file from its quarantine.
final class CannotRestore extends _Plain {
  const CannotRestore();
}

/// Undo: a folder on the way back to the original place is a file now.
final class FolderReplacedByFile extends OperationProblem {
  const FolderReplacedByFile(this.folder);

  final LogicalPath folder;

  @override
  bool operator ==(Object other) =>
      other is FolderReplacedByFile && other.folder == folder;

  @override
  int get hashCode => Object.hash(FolderReplacedByFile, folder);

  @override
  String toString() => 'FolderReplacedByFile($folder)';
}

/// Undo: the original place and every "restored" name next to it are taken.
final class NoFreeName extends OperationProblem {
  const NoFreeName(this.original);

  final LogicalPath original;

  @override
  bool operator ==(Object other) =>
      other is NoFreeName && other.original == original;

  @override
  int get hashCode => Object.hash(NoFreeName, original);

  @override
  String toString() => 'NoFreeName($original)';
}

/// Recovery: the process stopped before the operation took effect.
final class InterruptedOperation extends _Plain {
  const InterruptedOperation();
}

/// What recovery could not sort out.
enum AttentionCause {
  /// The file is neither at its old nor at its new place (nor in the
  /// quarantine).
  fileLost,

  /// The file could not be checked.
  cannotCheck,

  /// The quarantine could not be searched.
  cannotSearchQuarantine,
}

/// Recovery: the operation needs the user's attention.
final class NeedsAttention extends OperationProblem {
  const NeedsAttention(this.cause, {this.errorKind});

  final AttentionCause cause;

  /// The file source error behind [cause], if any.
  final FileErrorKind? errorKind;

  @override
  bool operator ==(Object other) =>
      other is NeedsAttention &&
      other.cause == cause &&
      other.errorKind == errorKind;

  @override
  int get hashCode => Object.hash(NeedsAttention, cause, errorKind);

  @override
  String toString() =>
      'NeedsAttention(${cause.name}'
      '${errorKind == null ? '' : ', ${errorKind!.name}'})';
}

/// A problem stored as free text before problems got codes (database
/// schema version 1). Never produced by the core.
final class LegacyProblem extends OperationProblem {
  const LegacyProblem(this.text);

  final String text;

  @override
  bool operator ==(Object other) =>
      other is LegacyProblem && other.text == text;

  @override
  int get hashCode => Object.hash(LegacyProblem, text);

  @override
  String toString() => 'LegacyProblem($text)';
}
