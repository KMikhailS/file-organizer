import 'package:meta/meta.dart';

/// Whether a path is a file or a folder.
enum FileKind { file, directory }

/// Metadata of a path.
@immutable
final class FileStat {
  /// Creates metadata. [modifiedAt] is stored in UTC.
  FileStat({
    required this.kind,
    required this.size,
    required DateTime modifiedAt,
  }) : modifiedAt = modifiedAt.toUtc();

  final FileKind kind;

  /// Size in bytes; 0 for folders.
  final int size;

  /// Last modification time, in UTC.
  final DateTime modifiedAt;

  bool get isFile => kind == FileKind.file;

  bool get isDirectory => kind == FileKind.directory;

  @override
  bool operator ==(Object other) =>
      other is FileStat &&
      other.kind == kind &&
      other.size == size &&
      other.modifiedAt == modifiedAt;

  @override
  int get hashCode => Object.hash(kind, size, modifiedAt);

  @override
  String toString() =>
      'FileStat(${kind.name}, size: $size, '
      'modifiedAt: ${modifiedAt.toIso8601String()})';
}
