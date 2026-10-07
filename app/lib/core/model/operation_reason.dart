import 'package:file_organizer/core/model/classification_reason.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:meta/meta.dart';

/// Why a plan contains an operation: a code with parameters. The UI turns it
/// into text through localization.
@immutable
sealed class OperationReason {
  const OperationReason();
}

/// A move: the file's classification decided its folder.
final class Classified extends OperationReason {
  const Classified(this.reason);

  final ClassificationReason reason;

  @override
  bool operator ==(Object other) =>
      other is Classified && other.reason == reason;

  @override
  int get hashCode => Object.hash(Classified, reason);

  @override
  String toString() => 'Classified($reason)';
}

/// A quarantine or album operation: the file is an extra copy of [keeper].
final class DuplicateOf extends OperationReason {
  const DuplicateOf(this.keeper);

  /// The copy that stays (its path at planning time).
  final LogicalPath keeper;

  @override
  bool operator ==(Object other) =>
      other is DuplicateOf && other.keeper == keeper;

  @override
  int get hashCode => Object.hash(DuplicateOf, keeper);

  @override
  String toString() => 'DuplicateOf($keeper)';
}

/// A mkdir: the target [folder] of the plan needs this folder.
final class FolderFor extends OperationReason {
  const FolderFor(this.folder);

  /// The target folder the moves go to (this folder or one inside it).
  final LogicalPath folder;

  @override
  bool operator ==(Object other) =>
      other is FolderFor && other.folder == folder;

  @override
  int get hashCode => Object.hash(FolderFor, folder);

  @override
  String toString() => 'FolderFor($folder)';
}

/// A quarantine that crash recovery added: the empty placeholder that an
/// interrupted move of [file] left at its target (decision A.5, fallback
/// "reserve the name, then rename"). Undo never restores it: the
/// placeholder was not part of the original tree.
final class MovePlaceholder extends OperationReason {
  const MovePlaceholder(this.file);

  /// The file whose move was interrupted (the move's source path).
  final LogicalPath file;

  @override
  bool operator ==(Object other) =>
      other is MovePlaceholder && other.file == file;

  @override
  int get hashCode => Object.hash(MovePlaceholder, file);

  @override
  String toString() => 'MovePlaceholder($file)';
}

/// A reason stored as free text before reasons got codes (database schema
/// version 1). Never produced by the core.
final class LegacyReason extends OperationReason {
  const LegacyReason(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is LegacyReason && other.text == text;

  @override
  int get hashCode => Object.hash(LegacyReason, text);

  @override
  String toString() => 'LegacyReason($text)';
}
