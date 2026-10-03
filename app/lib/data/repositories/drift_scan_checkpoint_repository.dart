import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';

final class DriftScanCheckpointRepository implements ScanCheckpointRepository {
  DriftScanCheckpointRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ScanCheckpoint?> bySource(SourceId sourceId) async {
    final row = await (_db.select(
      _db.scanCheckpoints,
    )..where((t) => t.sourceId.equals(sourceId.value))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return ScanCheckpoint(
      sourceId: SourceId(row.sourceId),
      scanId: ScanId(row.scanId),
      stage: ScanStage.values.byName(row.stage),
      cursor: row.cursor == null ? null : ScanCursor(row.cursor!),
    );
  }

  @override
  Future<void> save(ScanCheckpoint checkpoint) => _db
      .into(_db.scanCheckpoints)
      .insertOnConflictUpdate(
        ScanCheckpointRow(
          sourceId: checkpoint.sourceId.value,
          scanId: checkpoint.scanId.value,
          stage: checkpoint.stage.name,
          cursor: checkpoint.cursor?.value,
        ),
      );

  @override
  Future<void> clear(SourceId sourceId) => (_db.delete(
    _db.scanCheckpoints,
  )..where((t) => t.sourceId.equals(sourceId.value))).go();
}
