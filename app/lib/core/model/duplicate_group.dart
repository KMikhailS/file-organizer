import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:meta/meta.dart';

/// Why the keeper of a duplicate group was chosen. The values follow the
/// selection rules in order: the first rule that tells the files apart wins.
enum KeeperReason {
  /// It lies in an organized or target folder, the others in chaos zones.
  organizedLocation,

  /// It has the earliest modification time.
  earliestModified,

  /// Its name has no copy marker (`(1)`, `copy`, `копия`, `- Copy`).
  notACopy,

  /// It has the shortest path.
  shortestPath,

  /// Its path comes first alphabetically (deterministic tie-break).
  alphabeticalPath,
}

/// A group of identical files within one source and the copy to keep.
@immutable
final class DuplicateGroup {
  /// Creates a group. [files] are stored sorted by path, so equal groups
  /// compare equal regardless of input order.
  ///
  /// Throws [ArgumentError] unless: there are at least two files, all from
  /// one source, with distinct paths, the same non-zero size and
  /// [FileEntry.fullHash] equal to [fullHash]; and [keeper] is one of them.
  factory DuplicateGroup({
    required String fullHash,
    required Iterable<FileEntry> files,
    required FileEntry keeper,
    required KeeperReason keeperReason,
  }) {
    final sorted = files.toList()..sort((a, b) => a.path.compareTo(b.path));
    if (sorted.length < 2) {
      throw ArgumentError.value(sorted, 'files', 'needs at least two files');
    }
    final first = sorted.first;
    if (first.size == 0) {
      throw ArgumentError.value(
        sorted,
        'files',
        'empty files are not duplicates',
      );
    }
    for (var i = 0; i < sorted.length; i++) {
      final file = sorted[i];
      if (file.sourceId != first.sourceId) {
        throw ArgumentError.value(sorted, 'files', 'must share one source');
      }
      if (file.size != first.size) {
        throw ArgumentError.value(sorted, 'files', 'must have the same size');
      }
      if (file.fullHash != fullHash) {
        throw ArgumentError.value(
          sorted,
          'files',
          'must have fullHash $fullHash',
        );
      }
      if (i > 0 && file.path == sorted[i - 1].path) {
        throw ArgumentError.value(sorted, 'files', 'paths must be distinct');
      }
    }
    if (!sorted.contains(keeper)) {
      throw ArgumentError.value(keeper, 'keeper', 'must be one of the files');
    }
    return DuplicateGroup._(
      fullHash,
      List.unmodifiable(sorted),
      keeper,
      keeperReason,
    );
  }

  const DuplicateGroup._(
    this.fullHash,
    this.files,
    this.keeper,
    this.keeperReason,
  );

  final String fullHash;

  /// All copies, sorted by path. Unmodifiable.
  final List<FileEntry> files;

  /// The copy to keep.
  final FileEntry keeper;

  final KeeperReason keeperReason;

  SourceId get sourceId => keeper.sourceId;

  /// Size of one copy in bytes.
  int get size => keeper.size;

  /// The copies to get rid of, sorted by path.
  List<FileEntry> get extras =>
      List.unmodifiable(files.where((f) => f != keeper));

  /// Bytes freed by removing [extras].
  int get reclaimableBytes => size * (files.length - 1);

  @override
  bool operator ==(Object other) =>
      other is DuplicateGroup &&
      other.fullHash == fullHash &&
      listEquals(other.files, files) &&
      other.keeper == keeper &&
      other.keeperReason == keeperReason;

  @override
  int get hashCode =>
      Object.hash(fullHash, Object.hashAll(files), keeper, keeperReason);

  @override
  String toString() =>
      'DuplicateGroup($fullHash, ${files.length} files, '
      'keeper: ${keeper.path}, $keeperReason)';
}
