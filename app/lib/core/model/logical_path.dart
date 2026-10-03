import 'package:meta/meta.dart';

/// Path of a file or folder inside one source, relative to the source root,
/// with `/` as the separator (for example `Download/scan.pdf`).
///
/// The core never sees real OS paths; adapters translate logical paths to
/// them. A valid logical path cannot point outside its source: it has no
/// `.` or `..` segments, no empty segments and no leading or trailing `/`.
/// The empty path is the source root.
@immutable
final class LogicalPath implements Comparable<LogicalPath> {
  /// Creates a path from [value].
  ///
  /// Throws [ArgumentError] if [value] is not a valid logical path; see
  /// [problemWith].
  factory LogicalPath(String value) {
    final problem = problemWith(value);
    if (problem != null) {
      throw ArgumentError.value(value, 'value', problem);
    }
    return LogicalPath._(value);
  }

  const LogicalPath._(this.value);

  /// The root of a source.
  static const LogicalPath root = LogicalPath._('');

  /// Returns why [value] is not a valid logical path, or `null` if it is.
  static String? problemWith(String value) {
    if (value.isEmpty) {
      return null;
    }
    if (value.contains('\u0000')) {
      return 'must not contain NUL characters';
    }
    if (value.startsWith('/') || value.endsWith('/')) {
      return 'must not start or end with "/"';
    }
    for (final segment in value.split('/')) {
      if (segment.isEmpty) {
        return 'must not contain empty segments';
      }
      if (segment == '.' || segment == '..') {
        return 'must not contain "." or ".." segments';
      }
    }
    return null;
  }

  /// The path as a `/`-separated string; empty for [root].
  final String value;

  /// Whether this is the source root.
  bool get isRoot => value.isEmpty;

  /// The path segments; empty for [root].
  List<String> get segments =>
      isRoot ? const [] : List.unmodifiable(value.split('/'));

  /// The last segment (file or folder name); empty for [root].
  String get name => value.substring(value.lastIndexOf('/') + 1);

  /// The extension of [name] in lower case, without the dot.
  ///
  /// Empty if there is none. A leading dot does not start an extension
  /// (`.bashrc` has none); only the last one counts (`a.tar.gz` → `gz`).
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  /// [name] without the extension and its dot.
  String get stem {
    final dot = name.lastIndexOf('.');
    return dot <= 0 || dot == name.length - 1 ? name : name.substring(0, dot);
  }

  /// The parent folder, or `null` for [root].
  LogicalPath? get parent {
    if (isRoot) {
      return null;
    }
    final slash = value.lastIndexOf('/');
    return slash < 0 ? root : LogicalPath._(value.substring(0, slash));
  }

  /// This path followed by [other].
  LogicalPath join(LogicalPath other) {
    if (other.isRoot) {
      return this;
    }
    return isRoot ? other : LogicalPath._('$value/${other.value}');
  }

  /// This path followed by a single segment [name].
  ///
  /// Throws [ArgumentError] if [name] is not a valid single segment.
  LogicalPath child(String name) {
    if (name.isEmpty || name.contains('/')) {
      throw ArgumentError.value(name, 'name', 'must be a single segment');
    }
    return join(LogicalPath(name));
  }

  /// Whether this path lies strictly inside [ancestor].
  bool isWithin(LogicalPath ancestor) {
    if (ancestor.isRoot) {
      return !isRoot;
    }
    return value.startsWith('${ancestor.value}/');
  }

  /// Whether this path is [other] or lies inside it.
  bool isSameOrWithin(LogicalPath other) => this == other || isWithin(other);

  /// Orders paths by their string value (UTF-16 code units). Deterministic
  /// and independent of the locale.
  @override
  int compareTo(LogicalPath other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is LogicalPath && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
