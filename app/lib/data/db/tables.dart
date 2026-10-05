import 'package:drift/drift.dart';

// Storage conventions:
// - dates are INTEGER microseconds since the epoch, UTC (drift's default
//   seconds would lose the microseconds fingerprints compare);
// - enums are TEXT holding the Dart enum name, so adding a value never
//   shifts stored ones; renaming a value is a schema change;
// - paths are TEXT with the default BINARY collation: case-sensitive keys;
// - operation reasons and problems are TEXT holding JSON with a `code`
//   (see `reason_codec.dart`); renaming a code is a schema change.

@DataClassName('SourceRow')
class Sources extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get displayName => text()();

  /// Added in schema version 2; empty for sources of version 1.
  TextColumn get location => text().withDefault(const Constant(''))();
  BoolColumn get canMove => boolean()();
  BoolColumn get canMkdir => boolean()();
  BoolColumn get canQuarantine => boolean()();
  BoolColumn get quarantineRestorable => boolean()();
  BoolColumn get canAddToAlbum => boolean()();
  BoolColumn get providesCapturedAt => boolean()();
  BoolColumn get systemPurgesQuarantine => boolean()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FileIndexRow')
@TableIndex(name: 'file_index_by_size', columns: {#sourceId, #size})
@TableIndex(name: 'file_index_by_full_hash', columns: {#sourceId, #fullHash})
class FileIndex extends Table {
  TextColumn get sourceId => text()();
  TextColumn get path => text()();
  IntColumn get size => integer()();
  IntColumn get modifiedAt => integer()();
  IntColumn get capturedAt => integer().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get partialHash => text().nullable()();
  TextColumn get fullHash => text().nullable()();
  TextColumn get lastSeenScanId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sourceId, path};
}

@DataClassName('ScanCheckpointRow')
class ScanCheckpoints extends Table {
  TextColumn get sourceId => text()();
  TextColumn get scanId => text()();
  TextColumn get stage => text()();
  TextColumn get cursor => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sourceId};
}

@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  IntColumn get startedAt => integer()();
  IntColumn get finishedAt => integer().nullable()();
  TextColumn get status => text()();
  IntColumn get statTotal => integer()();
  IntColumn get statDone => integer()();
  IntColumn get statFailed => integer()();
  IntColumn get statSkipped => integer()();
  IntColumn get statReverted => integer()();
  IntColumn get statRevertSkipped => integer()();
  IntColumn get statRemovedBytes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OperationRow')
@TableIndex(
  name: 'operations_by_type_status',
  columns: {#type, #status, #executedAt},
)
class Operations extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  IntColumn get seq => integer()();
  TextColumn get type => text()();
  TextColumn get sourceId => text()();
  TextColumn get fromPath => text().nullable()();
  TextColumn get toPath => text().nullable()();
  IntColumn get fingerprintSize => integer().nullable()();
  IntColumn get fingerprintModifiedAt => integer().nullable()();
  TextColumn get fingerprintFullHash => text().nullable()();
  TextColumn get quarantineRef => text().nullable()();
  TextColumn get reason => text()();
  TextColumn get groupKey => text()();
  TextColumn get status => text()();
  TextColumn get error => text().nullable()();
  IntColumn get executedAt => integer().nullable()();
  IntColumn get revertedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sessionId, seq},
  ];
}

@DataClassName('ZoneOverrideRow')
class ZoneOverrides extends Table {
  TextColumn get sourceId => text()();
  TextColumn get folder => text()();
  TextColumn get zone => text()();

  @override
  Set<Column<Object>> get primaryKey => {sourceId, folder};
}

@DataClassName('ClassificationRuleRow')
class ClassificationRules extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  IntColumn get priority => integer()();

  /// Extensions joined by `,` (they never contain one), sorted.
  TextColumn get extensions => text()();
  TextColumn get nameContains => text().nullable()();
  TextColumn get folder => text().nullable()();
  TextColumn get sourceId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Key-value settings; see `DriftSettingsRepository` for the keys.
@DataClassName('SettingRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
