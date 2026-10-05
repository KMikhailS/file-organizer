import 'package:file_organizer/core/model/file_error_kind.dart';
import 'package:meta/meta.dart';

export 'package:file_organizer/core/model/file_error_kind.dart';

/// A typed file operation error.
@immutable
final class FileError {
  const FileError(this.kind, [this.message]);

  final FileErrorKind kind;

  /// Optional details for logs and reports.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is FileError && other.kind == kind && other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => message == null
      ? 'FileError(${kind.name})'
      : 'FileError(${kind.name}: $message)';
}
