import 'package:drift/native.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repository_contracts.dart';

/// Runs the repository contracts against the drift implementations, on a
/// fresh in-memory SQLite database per test. The in-memory implementations
/// run the same contracts (in_memory_contracts_test.dart).
void main() {
  Future<AppDatabase> database() async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    return db;
  }

  group('DriftSourceRepository', () {
    sourceRepositoryContract(
      () async => DriftSourceRepository(await database()),
    );
  });

  group('DriftFileIndexRepository', () {
    fileIndexRepositoryContract(
      () async => DriftFileIndexRepository(await database()),
    );
  });

  group('DriftScanCheckpointRepository', () {
    scanCheckpointRepositoryContract(
      () async => DriftScanCheckpointRepository(await database()),
    );
  });

  group('DriftSessionRepository', () {
    sessionRepositoryContract(
      () async => DriftSessionRepository(await database()),
    );
  });

  group('DriftRuleRepository', () {
    ruleRepositoryContract(() async => DriftRuleRepository(await database()));
  });

  group('DriftSettingsRepository', () {
    settingsRepositoryContract(
      () async => DriftSettingsRepository(await database()),
    );
  });

  group('DriftOperationJournal', () {
    operationJournalContract(
      () async => DriftOperationJournal(await database()),
    );
  });
}
