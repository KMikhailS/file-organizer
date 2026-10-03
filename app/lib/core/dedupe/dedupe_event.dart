import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/duplicate_group.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:meta/meta.dart';

/// Progress and outcome of duplicate detection. The stream ends with
/// [DedupeCompleted].
@immutable
sealed class DedupeEvent {
  const DedupeEvent(this.sourceId);

  final SourceId sourceId;
}

/// A size bucket was processed.
final class DedupeProgress extends DedupeEvent {
  const DedupeProgress(
    super.sourceId, {
    required this.sizesDone,
    required this.sizesTotal,
    required this.filesHashed,
  });

  /// Buckets of same-size files processed so far, out of [sizesTotal].
  final int sizesDone;

  final int sizesTotal;

  /// Hashes computed so far (cached hashes are not counted).
  final int filesHashed;

  @override
  bool operator ==(Object other) =>
      other is DedupeProgress &&
      other.sourceId == sourceId &&
      other.sizesDone == sizesDone &&
      other.sizesTotal == sizesTotal &&
      other.filesHashed == filesHashed;

  @override
  int get hashCode => Object.hash(sourceId, sizesDone, sizesTotal, filesHashed);

  @override
  String toString() =>
      'DedupeProgress($sourceId, $sizesDone/$sizesTotal sizes, '
      '$filesHashed hashed)';
}

/// Detection finished.
final class DedupeCompleted extends DedupeEvent {
  DedupeCompleted(
    super.sourceId, {
    required Iterable<DuplicateGroup> groups,
    required Iterable<DedupeSkip> skipped,
    required this.filesHashed,
  }) : groups = List.unmodifiable(groups),
       skipped = List.unmodifiable(skipped);

  /// Groups of identical files, sorted by the keeper's path.
  final List<DuplicateGroup> groups;

  /// Files that could not be hashed and took no further part.
  final List<DedupeSkip> skipped;

  /// Hashes computed in this run.
  final int filesHashed;

  @override
  bool operator ==(Object other) =>
      other is DedupeCompleted &&
      other.sourceId == sourceId &&
      other.filesHashed == filesHashed &&
      listEquals(other.groups, groups) &&
      listEquals(other.skipped, skipped);

  @override
  int get hashCode => Object.hash(
    sourceId,
    filesHashed,
    Object.hashAll(groups),
    Object.hashAll(skipped),
  );

  @override
  String toString() =>
      'DedupeCompleted($sourceId, ${groups.length} groups, '
      '${skipped.length} skipped)';
}

/// A file left out because hashing it failed.
@immutable
final class DedupeSkip {
  const DedupeSkip(this.path, this.error);

  final LogicalPath path;

  final FileError error;

  @override
  bool operator ==(Object other) =>
      other is DedupeSkip && other.path == path && other.error == error;

  @override
  int get hashCode => Object.hash(path, error);

  @override
  String toString() => 'DedupeSkip($path, $error)';
}
