import 'package:drift/drift.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';

final class DriftRuleRepository implements RuleRepository {
  DriftRuleRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ZoneOverride>> zoneOverrides(SourceId sourceId) async {
    final rows = await (_db.select(
      _db.zoneOverrides,
    )..where((t) => t.sourceId.equals(sourceId.value))).get();
    return [
      for (final row in rows)
        ZoneOverride(
          sourceId: SourceId(row.sourceId),
          folder: LogicalPath(row.folder),
          zone: Zone.values.byName(row.zone),
        ),
    ]..sort((a, b) => a.folder.compareTo(b.folder));
  }

  @override
  Future<void> saveZoneOverride(ZoneOverride override) => _db
      .into(_db.zoneOverrides)
      .insertOnConflictUpdate(
        ZoneOverrideRow(
          sourceId: override.sourceId.value,
          folder: override.folder.value,
          zone: override.zone.name,
        ),
      );

  @override
  Future<void> removeZoneOverride(SourceId sourceId, LogicalPath folder) =>
      (_db.delete(_db.zoneOverrides)..where(
            (t) =>
                t.sourceId.equals(sourceId.value) &
                t.folder.equals(folder.value),
          ))
          .go();

  @override
  Future<List<ClassificationRule>> classificationRules() async {
    final rows = await _db.select(_db.classificationRules).get();
    return [
      for (final row in rows)
        ClassificationRule(
          id: row.id,
          category: Category.values.byName(row.category),
          priority: row.priority,
          extensions: row.extensions.isEmpty
              ? const {}
              : row.extensions.split(',').toSet(),
          nameContains: row.nameContains,
          folder: row.folder == null ? null : LogicalPath(row.folder!),
          sourceId: row.sourceId == null ? null : SourceId(row.sourceId!),
        ),
    ]..sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
    });
  }

  @override
  Future<void> saveClassificationRule(ClassificationRule rule) => _db
      .into(_db.classificationRules)
      .insertOnConflictUpdate(
        ClassificationRuleRow(
          id: rule.id,
          category: rule.category.name,
          priority: rule.priority,
          extensions: (rule.extensions.toList()..sort()).join(','),
          nameContains: rule.nameContains,
          folder: rule.folder?.value,
          sourceId: rule.sourceId?.value,
        ),
      );

  @override
  Future<void> removeClassificationRule(String id) =>
      (_db.delete(_db.classificationRules)..where((t) => t.id.equals(id))).go();
}
