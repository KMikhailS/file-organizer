import 'package:drift/drift.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/converters.dart';

/// Lists are sorted in Dart, by [LogicalPath.compareTo]: SQLite orders
/// text by UTF-8 bytes, which differs from Dart's UTF-16 order for some
/// characters (such as emoji), and the core relies on one stable order.
final class DriftFileIndexRepository implements FileIndexRepository {
  DriftFileIndexRepository(this._db);

  final AppDatabase _db;

  $FileIndexTable get _t => _db.fileIndex;

  @override
  Future<void> upsertAll(Iterable<FileEntry> entries) => _db.batch(
    (batch) => batch.insertAllOnConflictUpdate(_t, entries.map(_toRow)),
  );

  @override
  Future<FileEntry?> byPath(SourceId sourceId, LogicalPath path) async {
    final row =
        await (_db.select(_t)..where(
              (t) =>
                  t.sourceId.equals(sourceId.value) & t.path.equals(path.value),
            ))
            .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<Map<LogicalPath, FileEntry>> byPaths(
    SourceId sourceId,
    Iterable<LogicalPath> paths,
  ) async {
    final result = <LogicalPath, FileEntry>{};
    for (final chunk in chunked([for (final p in paths) p.value])) {
      final rows =
          await (_db.select(_t)..where(
                (t) => t.sourceId.equals(sourceId.value) & t.path.isIn(chunk),
              ))
              .get();
      for (final row in rows) {
        final entry = _toModel(row);
        result[entry.path] = entry;
      }
    }
    return result;
  }

  @override
  Future<List<FileEntry>> bySource(SourceId sourceId) =>
      _list(_db.select(_t)..where((t) => t.sourceId.equals(sourceId.value)));

  @override
  Future<List<int>> sizesWithMultipleFiles(SourceId sourceId) async {
    final count = _t.path.count();
    final query = _db.selectOnly(_t)
      ..addColumns([_t.size])
      ..where(_t.sourceId.equals(sourceId.value))
      ..groupBy([_t.size], having: count.isBiggerThanValue(1))
      ..orderBy([OrderingTerm.asc(_t.size)]);
    return [for (final row in await query.get()) row.read(_t.size)!];
  }

  @override
  Future<List<FileEntry>> bySize(SourceId sourceId, int size) => _list(
    _db.select(_t)
      ..where((t) => t.sourceId.equals(sourceId.value) & t.size.equals(size)),
  );

  @override
  Future<List<FileEntry>> byFullHash(SourceId sourceId, String fullHash) =>
      _list(
        _db.select(_t)..where(
          (t) =>
              t.sourceId.equals(sourceId.value) & t.fullHash.equals(fullHash),
        ),
      );

  @override
  Future<int> removeNotSeenIn(SourceId sourceId, ScanId scanId) =>
      (_db.delete(_t)..where(
            (t) =>
                t.sourceId.equals(sourceId.value) &
                (t.lastSeenScanId.isNull() |
                    t.lastSeenScanId.equals(scanId.value).not()),
          ))
          .go();

  Future<List<FileEntry>> _list(
    SimpleSelectStatement<$FileIndexTable, FileIndexRow> query,
  ) async =>
      (await query.get()).map(_toModel).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  static FileIndexRow _toRow(FileEntry e) => FileIndexRow(
    sourceId: e.sourceId.value,
    path: e.path.value,
    size: e.size,
    modifiedAt: toMicros(e.modifiedAt),
    capturedAt: e.capturedAt == null ? null : toMicros(e.capturedAt!),
    mimeType: e.mimeType,
    partialHash: e.partialHash,
    fullHash: e.fullHash,
    lastSeenScanId: e.lastSeenScanId?.value,
  );

  static FileEntry _toModel(FileIndexRow row) => FileEntry(
    sourceId: SourceId(row.sourceId),
    path: LogicalPath(row.path),
    size: row.size,
    modifiedAt: fromMicros(row.modifiedAt),
    capturedAt: fromMicrosOrNull(row.capturedAt),
    mimeType: row.mimeType,
    partialHash: row.partialHash,
    fullHash: row.fullHash,
    lastSeenScanId: row.lastSeenScanId == null
        ? null
        : ScanId(row.lastSeenScanId!),
  );
}
