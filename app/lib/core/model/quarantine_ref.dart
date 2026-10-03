import 'package:meta/meta.dart';

/// Opaque reference to a quarantined file: an entry in the app's quarantine
/// folder, in the system trash or in an album. Only the adapter that created
/// it understands [value].
///
/// This is the only thing that can be purged: there is no way to delete an
/// arbitrary file.
@immutable
final class QuarantineRef {
  /// Throws [ArgumentError] if [value] is empty.
  QuarantineRef(this.value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be empty');
    }
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      other is QuarantineRef && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'QuarantineRef($value)';
}
