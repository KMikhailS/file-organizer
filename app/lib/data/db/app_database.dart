import 'package:drift/drift.dart';
import 'package:file_organizer/data/db/app_database.steps.dart';
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

  /// Bump with every schema change, run `dart run drift_dev make-migrations`
  /// and add a step below.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        // Sources get the adapter's location; old ones stay empty (unknown).
        await m.addColumn(schema.sources, schema.sources.location);
        // Free-text reasons and errors become the `legacy` code with the
        // original text (see reason_codec.dart).
        await customStatement(
          "UPDATE operations SET reason = json_object('code', 'legacy', "
          "'text', reason)",
        );
        await customStatement(
          "UPDATE operations SET error = json_object('code', 'legacy', "
          "'text', error) WHERE error IS NOT NULL",
        );
      },
    ),
  );
}
