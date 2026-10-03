import 'package:meta/meta.dart';

/// Why a file operation failed.
enum FileErrorKind {
  /// The path (or the quarantine object) does not exist.
  notFound,

  /// Something already exists at the target. Nothing is ever overwritten.
  targetExists,

  /// The OS or the user did not grant access.
  permissionDenied,

  /// The file is in use by another process.
  locked,

  /// The source cannot do this (see its capabilities).
  unsupported,

  /// A folder to remove is not empty.
  notEmpty,

  /// A file was expected but the path is a folder, or the other way round.
  wrongType,

  /// Any other I/O failure.
  ioError,
}

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
