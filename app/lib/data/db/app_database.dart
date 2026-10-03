import 'package:drift/drift.dart';
import 'package:file_organizer/data/db/tables.dart';

part 'app_database.g.dart';

/// The local SQLite database: index, journal, sessions, rules, settings.
///
/// The executor is given by the caller: a file database on the device
/// (wired up with the app) or an in-memory one in tests.
@DriftDatabase(
  tables: [
    Sources,
    FileIndex,
    ScanCheckpoints,
    Sessions,
    Operations,
    ZoneOverrides,
    ClassificationRules,
    SettingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump with every schema change and add a migration step below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Version 1 is the first one: there is nothing to upgrade from yet.
      throw StateError('No migration from schema $from to $to');
    },
  );
}
