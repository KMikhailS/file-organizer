import 'dart:convert';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';

/// Settings as key-value rows; a missing key means the default.
final class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  /// Retention of the quarantine, in microseconds.
  static const String quarantineRetentionKey = 'quarantine_retention_us';

  /// Folder names of the layout template: a JSON object from the category
  /// name to the folder name. Missing until they are fixed.
  static const String layoutFolderNamesKey = 'layout_folder_names';

  /// Language of the UI (BCP 47). Missing: the system language.
  static const String uiLocaleKey = 'ui_locale';

  final AppDatabase _db;

  @override
  Future<Settings> load() async {
    final rows = await _db.select(_db.settingsTable).get();
    final values = {for (final row in rows) row.key: row.value};
    final retention = values[quarantineRetentionKey];
    final folderNames = values[layoutFolderNamesKey];
    return Settings(
      quarantineRetention: retention == null
          ? Settings.defaultQuarantineRetention
          : Duration(microseconds: int.parse(retention)),
      layoutFolderNames: folderNames == null
          ? null
          : {
              for (final MapEntry(:key, :value)
                  in (jsonDecode(folderNames) as Map<String, Object?>).entries)
                Category.values.byName(key): value! as String,
            },
      uiLocale: values[uiLocaleKey],
    );
  }

  @override
  Future<void> save(Settings settings) => _db.transaction(() async {
    final names = settings.layoutFolderNames;
    final values = <String, String?>{
      quarantineRetentionKey: '${settings.quarantineRetention.inMicroseconds}',
      layoutFolderNamesKey: names == null
          ? null
          : jsonEncode({
              for (final MapEntry(:key, :value) in names.entries)
                key.name: value,
            }),
      uiLocaleKey: settings.uiLocale,
    };
    for (final MapEntry(:key, :value) in values.entries) {
      if (value == null) {
        await (_db.delete(
          _db.settingsTable,
        )..where((t) => t.key.equals(key))).go();
      } else {
        await _db
            .into(_db.settingsTable)
            .insertOnConflictUpdate(SettingRow(key: key, value: value));
      }
    }
  });
}
