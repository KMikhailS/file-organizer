import 'package:file_organizer/core/model/fingerprint.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:meta/meta.dart';

/// A file in the index.
@immutable
final class FileEntry {
  /// Creates an entry. Dates are stored in UTC.
  ///
  /// Throws [ArgumentError] if [path] is the source root or [size] is
  /// negative.
  FileEntry({
    required this.sourceId,
    required this.path,
    required this.size,
    required DateTime modifiedAt,
    DateTime? capturedAt,
    this.mimeType,
    this.partialHash,
    this.fullHash,
    this.lastSeenScanId,
  }) : modifiedAt = modifiedAt.toUtc(),
       capturedAt = capturedAt?.toUtc() {
    if (path.isRoot) {
      throw ArgumentError.value(path, 'path', 'must not be the source root');
    }
    RangeError.checkNotNegative(size, 'size');
  }

  final SourceId sourceId;

  /// Logical path inside the source.
  final LogicalPath path;

  /// Size in bytes.
  final int size;

  /// Last modification time, in UTC.
  final DateTime modifiedAt;

  /// Capture date, in UTC, if the adapter can provide it cheaply (MediaStore,
  /// PhotoKit, EXIF).
  final DateTime? capturedAt;

  final String? mimeType;

  /// Hash of the first and last 64 KB together with the size. Filled in by
  /// duplicate detection.
  final String? partialHash;

  /// Full content hash. Filled in by duplicate detection.
  final String? fullHash;

  /// The scan in which the file was last seen.
  final ScanId? lastSeenScanId;

  /// File name, derived from [path].
  String get name => path.name;

  /// Lower-case extension without the dot, derived from [path].
  String get extension => path.extension;

  /// A copy with [partialHash] set.
  FileEntry withPartialHash(String partialHash) =>
      _copy(partialHash: partialHash, fullHash: fullHash);

  /// A copy with [fullHash] set.
  FileEntry withFullHash(String fullHash) =>
      _copy(partialHash: partialHash, fullHash: fullHash);

  FileEntry _copy({required String? partialHash, required String? fullHash}) =>
      FileEntry(
        sourceId: sourceId,
        path: path,
        size: size,
        modifiedAt: modifiedAt,
        capturedAt: capturedAt,
        mimeType: mimeType,
        partialHash: partialHash,
        fullHash: fullHash,
        lastSeenScanId: lastSeenScanId,
      );

  /// The fingerprint of this file as indexed.
  Fingerprint get fingerprint =>
      Fingerprint(size: size, modifiedAt: modifiedAt, fullHash: fullHash);

  @override
  bool operator ==(Object other) =>
      other is FileEntry &&
      other.sourceId == sourceId &&
      other.path == path &&
      other.size == size &&
      other.modifiedAt == modifiedAt &&
      other.capturedAt == capturedAt &&
      other.mimeType == mimeType &&
      other.partialHash == partialHash &&
      other.fullHash == fullHash &&
      other.lastSeenScanId == lastSeenScanId;

  @override
  int get hashCode => Object.hash(
    sourceId,
    path,
    size,
    modifiedAt,
    capturedAt,
    mimeType,
    partialHash,
    fullHash,
    lastSeenScanId,
  );

  @override
  String toString() => 'FileEntry($sourceId:$path, size: $size)';
}
