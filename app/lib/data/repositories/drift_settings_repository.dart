import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';

/// Settings as key-value rows; a missing key means the default.
final class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  /// Retention of the quarantine, in microseconds.
  static const String quarantineRetentionKey = 'quarantine_retention_us';

  final AppDatabase _db;

  @override
  Future<Settings> load() async {
    final rows = await _db.select(_db.settingsTable).get();
    final values = {for (final row in rows) row.key: row.value};
    final retention = values[quarantineRetentionKey];
    return Settings(
      quarantineRetention: retention == null
          ? Settings.defaultQuarantineRetention
          : Duration(microseconds: int.parse(retention)),
    );
  }

  @override
  Future<void> save(Settings settings) => _db
      .into(_db.settingsTable)
      .insertOnConflictUpdate(
        SettingRow(
          key: quarantineRetentionKey,
          value: '${settings.quarantineRetention.inMicroseconds}',
        ),
      );
}
