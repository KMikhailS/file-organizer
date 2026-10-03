import 'package:meta/meta.dart';

/// State of one file in a snapshot.
@immutable
final class SnapshotFile {
  const SnapshotFile({
    required this.size,
    required this.contentHash,
    required this.modifiedAt,
    this.capturedAt,
  });

  final int size;

  final String contentHash;

  final DateTime modifiedAt;

  final DateTime? capturedAt;

  @override
  bool operator ==(Object other) =>
      other is SnapshotFile &&
      other.size == size &&
      other.contentHash == contentHash &&
      other.modifiedAt == modifiedAt &&
      other.capturedAt == capturedAt;

  @override
  int get hashCode => Object.hash(size, contentHash, modifiedAt, capturedAt);

  @override
  String toString() =>
      '$size bytes, $contentHash, ${modifiedAt.toIso8601String()}';
}

/// Immutable picture of a fake file source, for "before" and "after"
/// comparisons.
@immutable
final class FsSnapshot {
  FsSnapshot({
    required Map<String, SnapshotFile> files,
    required Set<String> directories,
    required Map<String, SnapshotFile> quarantined,
    required Set<String> album,
  }) : files = Map.unmodifiable(files),
       directories = Set.unmodifiable(directories),
       quarantined = Map.unmodifiable(quarantined),
       album = Set.unmodifiable(album);

  /// Files of the tree by path.
  final Map<String, SnapshotFile> files;

  /// Folders of the tree (the root is not listed).
  final Set<String> directories;

  /// Quarantined files by quarantine reference.
  final Map<String, SnapshotFile> quarantined;

  /// Paths in the "to delete" album.
  final Set<String> album;

  /// Only the visible tree: files and folders, without quarantine and album.
  FsSnapshot get tree => FsSnapshot(
    files: files,
    directories: directories,
    quarantined: const {},
    album: const {},
  );

  /// Human-readable differences from [other] (this is "before", [other] is
  /// "after"); empty if equal.
  List<String> diff(FsSnapshot other) {
    final out = <String>[];
    void compareMaps(
      String what,
      Map<String, SnapshotFile> a,
      Map<String, SnapshotFile> b,
    ) {
      for (final key in {...a.keys, ...b.keys}.toList()..sort()) {
        final before = a[key];
        final after = b[key];
        if (before == null) {
          out.add('+ $what $key ($after)');
        } else if (after == null) {
          out.add('- $what $key ($before)');
        } else if (before != after) {
          out.add('~ $what $key: $before -> $after');
        }
      }
    }

    void compareSets(String what, Set<String> a, Set<String> b) {
      for (final key in a.difference(b).toList()..sort()) {
        out.add('- $what $key');
      }
      for (final key in b.difference(a).toList()..sort()) {
        out.add('+ $what $key');
      }
    }

    compareMaps('file', files, other.files);
    compareSets('dir', directories, other.directories);
    compareMaps('quarantined', quarantined, other.quarantined);
    compareSets('album', album, other.album);
    return out;
  }

  @override
  bool operator ==(Object other) => other is FsSnapshot && diff(other).isEmpty;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      files.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(directories),
    Object.hashAllUnordered(
      quarantined.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(album),
  );

  @override
  String toString() =>
      'FsSnapshot(${files.length} files, ${directories.length} dirs, '
      '${quarantined.length} quarantined, ${album.length} in album)';
}
