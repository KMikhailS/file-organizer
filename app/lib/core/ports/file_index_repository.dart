import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';

/// The file index. An entry is identified by its source and path.
///
/// Lists are sorted by path, so results are deterministic.
abstract interface class FileIndexRepository {
  /// Inserts [entries] or replaces the ones with the same source and path,
  /// in one batch.
  Future<void> upsertAll(Iterable<FileEntry> entries);

  Future<FileEntry?> byPath(SourceId sourceId, LogicalPath path);

  /// The entries of a source found at [paths], by path. Paths without an
  /// entry are absent from the map. Used to look up a whole listing page at
  /// once.
  Future<Map<LogicalPath, FileEntry>> byPaths(
    SourceId sourceId,
    Iterable<LogicalPath> paths,
  );

  /// All entries of a source.
  Future<List<FileEntry>> bySource(SourceId sourceId);

  /// Sizes shared by at least two entries of a source, ascending.
  Future<List<int>> sizesWithMultipleFiles(SourceId sourceId);

  /// Entries of a source with the given size.
  Future<List<FileEntry>> bySize(SourceId sourceId, int size);

  /// Entries of a source with the given full hash.
  Future<List<FileEntry>> byFullHash(SourceId sourceId, String fullHash);

  /// Removes the entries of a source that were not seen in [scanId] and
  /// returns how many were removed. Only index records are removed, never
  /// files.
  Future<int> removeNotSeenIn(SourceId sourceId, ScanId scanId);
}
