import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemoryFileIndexRepository implements FileIndexRepository {
  /// Entries by source, then by path.
  final Map<SourceId, Map<LogicalPath, FileEntry>> _entries = {};

  @override
  Future<void> upsertAll(Iterable<FileEntry> entries) async {
    for (final entry in entries) {
      (_entries[entry.sourceId] ??= {})[entry.path] = entry;
    }
  }

  @override
  Future<FileEntry?> byPath(SourceId sourceId, LogicalPath path) async =>
      _entries[sourceId]?[path];

  @override
  Future<Map<LogicalPath, FileEntry>> byPaths(
    SourceId sourceId,
    Iterable<LogicalPath> paths,
  ) async {
    final entries = _entries[sourceId] ?? const <LogicalPath, FileEntry>{};
    return {for (final path in paths) path: ?entries[path]};
  }

  @override
  Future<List<FileEntry>> bySource(SourceId sourceId) async =>
      _sorted(_entries[sourceId]?.values ?? const []);

  @override
  Future<List<int>> sizesWithMultipleFiles(SourceId sourceId) async {
    final counts = <int, int>{};
    for (final entry in _entries[sourceId]?.values ?? const <FileEntry>[]) {
      counts[entry.size] = (counts[entry.size] ?? 0) + 1;
    }
    return [
      for (final MapEntry(:key, :value) in counts.entries)
        if (value > 1) key,
    ]..sort();
  }

  @override
  Future<List<FileEntry>> bySize(SourceId sourceId, int size) async => _sorted(
    (_entries[sourceId]?.values ?? const <FileEntry>[]).where(
      (e) => e.size == size,
    ),
  );

  @override
  Future<List<FileEntry>> byFullHash(
    SourceId sourceId,
    String fullHash,
  ) async => _sorted(
    (_entries[sourceId]?.values ?? const <FileEntry>[]).where(
      (e) => e.fullHash == fullHash,
    ),
  );

  @override
  Future<int> removeNotSeenIn(SourceId sourceId, ScanId scanId) async {
    final entries = _entries[sourceId];
    if (entries == null) {
      return 0;
    }
    final before = entries.length;
    entries.removeWhere((_, e) => e.lastSeenScanId != scanId);
    return before - entries.length;
  }

  static List<FileEntry> _sorted(Iterable<FileEntry> entries) =>
      entries.toList()..sort((a, b) => a.path.compareTo(b.path));
}
