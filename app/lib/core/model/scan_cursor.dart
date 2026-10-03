import 'package:meta/meta.dart';

/// Opaque position in a file listing, produced by a `FileSource` after each
/// page. Passing it back resumes the listing after that page. Only the
/// source that produced it understands [value].
@immutable
final class ScanCursor {
  const ScanCursor(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is ScanCursor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ScanCursor($value)';
}
