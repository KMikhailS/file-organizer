import 'package:flutter_test/flutter_test.dart';

import '../support/fs/in_memory_file_source.dart';
import '../support/repositories/in_memory_repositories.dart';
import 'file_source_contract.dart';
import 'repository_contracts.dart';

/// Runs the port contracts against the in-memory implementations. The drift
/// repositories (task 13) and the desktop file source (stage 2) run the same
/// contracts.
void main() {
  group('InMemoryFileSource', () {
    fileSourceContract(() async => _InMemoryFixture(pageSize: 1));
  });

  group('InMemoryFileSource, large pages', () {
    fileSourceContract(() async => _InMemoryFixture(pageSize: 100));
  });

  group('InMemorySourceRepository', () {
    sourceRepositoryContract(() async => InMemorySourceRepository());
  });

  group('InMemoryFileIndexRepository', () {
    fileIndexRepositoryContract(() async => InMemoryFileIndexRepository());
  });

  group('InMemoryScanCheckpointRepository', () {
    scanCheckpointRepositoryContract(
      () async => InMemoryScanCheckpointRepository(),
    );
  });

  group('InMemorySessionRepository', () {
    sessionRepositoryContract(() async => InMemorySessionRepository());
  });

  group('InMemoryRuleRepository', () {
    ruleRepositoryContract(() async => InMemoryRuleRepository());
  });

  group('InMemorySettingsRepository', () {
    settingsRepositoryContract(() async => InMemorySettingsRepository());
  });

  group('InMemoryOperationJournal', () {
    operationJournalContract(() async => InMemoryOperationJournal());
  });
}

final class _InMemoryFixture implements FileSourceFixture {
  _InMemoryFixture({required int pageSize})
    : source = InMemoryFileSource(pageSize: pageSize);

  @override
  final InMemoryFileSource source;

  @override
  Future<void> givenFile(
    String path, {
    required List<int> bytes,
    required DateTime modifiedAt,
  }) async {
    if (source.isFile(path)) {
      source.writeFile(path, bytes: bytes, modifiedAt: modifiedAt);
    } else {
      source.addFile(path, bytes: bytes, modifiedAt: modifiedAt);
    }
  }

  @override
  Future<void> givenDir(String path) async => source.addDir(path);
}
