import 'package:file_organizer/core/ports/file_error.dart';
import 'package:meta/meta.dart';

/// Outcome of a `FileSource` call: a value or a typed error. File sources
/// never throw for expected failures.
@immutable
sealed class FileResult<T> {
  const FileResult();

  /// Whether this is a [FileSuccess].
  bool get isSuccess => this is FileSuccess<T>;

  /// The error kind, or `null` on success.
  FileErrorKind? get errorKind => switch (this) {
    FileSuccess<T>() => null,
    FileFailure<T>(:final error) => error.kind,
  };
}

/// A successful call with its [value].
final class FileSuccess<T> extends FileResult<T> {
  const FileSuccess(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is FileSuccess<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FileSuccess($value)';
}

/// A failed call. Nothing was changed.
final class FileFailure<T> extends FileResult<T> {
  const FileFailure(this.error);

  /// Shorthand for a failure of [kind].
  FileFailure.of(FileErrorKind kind, [String? message])
    : error = FileError(kind, message);

  final FileError error;

  @override
  bool operator ==(Object other) =>
      other is FileFailure<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'FileFailure($error)';
}

/// The success value of operations that return nothing.
const FileResult<void> succeeded = FileSuccess<void>(null);
