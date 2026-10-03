import 'package:meta/meta.dart';

/// What a file looked like when it was indexed. Used before an operation and
/// before an undo to make sure the file has not changed in between.
@immutable
final class Fingerprint {
  /// Creates a fingerprint. [modifiedAt] is stored in UTC.
  ///
  /// Throws [ArgumentError] if [size] is negative.
  Fingerprint({required this.size, required DateTime modifiedAt, this.fullHash})
    : modifiedAt = modifiedAt.toUtc() {
    RangeError.checkNotNegative(size, 'size');
  }

  /// Size in bytes.
  final int size;

  /// Last modification time, in UTC.
  final DateTime modifiedAt;

  /// Full content hash, if it was computed.
  final String? fullHash;

  @override
  bool operator ==(Object other) =>
      other is Fingerprint &&
      other.size == size &&
      other.modifiedAt == modifiedAt &&
      other.fullHash == fullHash;

  @override
  int get hashCode => Object.hash(size, modifiedAt, fullHash);

  @override
  String toString() =>
      'Fingerprint(size: $size, modifiedAt: ${modifiedAt.toIso8601String()}, '
      'fullHash: $fullHash)';
}
