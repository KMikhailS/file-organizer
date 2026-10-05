import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';

final class DriftSourceRepository implements SourceRepository {
  DriftSourceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Source>> all() async {
    final rows = await _db.select(_db.sources).get();
    return rows.map(_toModel).toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
  }

  @override
  Future<Source?> byId(SourceId id) async {
    final row = await (_db.select(
      _db.sources,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<void> save(Source source) async {
    final c = source.capabilities;
    await _db
        .into(_db.sources)
        .insertOnConflictUpdate(
          SourceRow(
            id: source.id.value,
            kind: source.kind.name,
            displayName: source.displayName,
            location: source.location,
            canMove: c.canMove,
            canMkdir: c.canMkdir,
            canQuarantine: c.canQuarantine,
            quarantineRestorable: c.quarantineRestorable,
            canAddToAlbum: c.canAddToAlbum,
            providesCapturedAt: c.providesCapturedAt,
            systemPurgesQuarantine: c.systemPurgesQuarantine,
            enabled: source.enabled,
          ),
        );
  }

  static Source _toModel(SourceRow row) => Source(
    id: SourceId(row.id),
    kind: SourceKind.values.byName(row.kind),
    displayName: row.displayName,
    location: row.location,
    capabilities: SourceCapabilities(
      canMove: row.canMove,
      canMkdir: row.canMkdir,
      canQuarantine: row.canQuarantine,
      quarantineRestorable: row.quarantineRestorable,
      canAddToAlbum: row.canAddToAlbum,
      providesCapturedAt: row.providesCapturedAt,
      systemPurgesQuarantine: row.systemPurgesQuarantine,
    ),
    enabled: row.enabled,
  );
}
