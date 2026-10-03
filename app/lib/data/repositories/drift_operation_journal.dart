import 'package:drift/drift.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/converters.dart';

/// The journal enforces [RepositoryRules] inside transactions, exactly like
/// the in-memory journal.
final class DriftOperationJournal implements OperationJournal {
  DriftOperationJournal(this._db);

  final AppDatabase _db;

  $OperationsTable get _t => _db.operations;

  @override
  Future<void> append(Operation operation) => _db.transaction(() async {
    RepositoryRules.checkAppend(operation);
    if (await byId(operation.id) != null) {
      throw StateError('Journal: ${operation.id} already exists');
    }
    final sameSeq =
        await (_db.select(_t)..where(
              (t) =>
                  t.sessionId.equals(operation.sessionId.value) &
                  t.seq.equals(operation.seq),
            ))
            .getSingleOrNull();
    if (sameSeq != null) {
      throw StateError(
        'Journal: seq ${operation.seq} is taken in ${operation.sessionId}',
      );
    }
    await _db.into(_t).insert(_toRow(operation));
  });

  @override
  Future<void> update(Operation operation) => _db.transaction(() async {
    final stored = await byId(operation.id);
    if (stored == null) {
      throw StateError('Journal: ${operation.id} does not exist');
    }
    RepositoryRules.checkUpdate(stored, operation);
    await _db.update(_t).replace(_toRow(operation));
  });

  @override
  Future<Operation?> byId(OperationId id) async {
    final row = await (_db.select(
      _t,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<Operation>> bySession(
    SessionId sessionId, {
    String? groupKey,
    bool reverse = false,
  }) async {
    final query = _db.select(_t)
      ..where(
        (t) =>
            t.sessionId.equals(sessionId.value) &
            (groupKey == null
                ? const Constant(true)
                : t.groupKey.equals(groupKey)),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.seq,
          mode: reverse ? OrderingMode.desc : OrderingMode.asc,
        ),
      ]);
    return (await query.get()).map(_toModel).toList();
  }

  @override
  Future<List<Operation>> doneQuarantinesBefore(DateTime cutoff) async {
    final rows =
        await (_db.select(_t)..where(
              (t) =>
                  t.type.equals(OperationType.quarantine.name) &
                  t.status.equals(OperationStatus.done.name) &
                  t.executedAt.isSmallerThanValue(toMicros(cutoff)),
            ))
            .get();
    return rows.map(_toModel).toList()..sort((a, b) {
      final byTime = a.executedAt!.compareTo(b.executedAt!);
      return byTime != 0 ? byTime : a.id.value.compareTo(b.id.value);
    });
  }

  static OperationRow _toRow(Operation o) => OperationRow(
    id: o.id.value,
    sessionId: o.sessionId.value,
    seq: o.seq,
    type: o.type.name,
    sourceId: o.sourceId.value,
    fromPath: o.fromPath?.value,
    toPath: o.toPath?.value,
    fingerprintSize: o.fingerprint?.size,
    fingerprintModifiedAt: o.fingerprint == null
        ? null
        : toMicros(o.fingerprint!.modifiedAt),
    fingerprintFullHash: o.fingerprint?.fullHash,
    quarantineRef: o.quarantineRef?.value,
    reason: o.reason,
    groupKey: o.groupKey,
    status: o.status.name,
    error: o.error,
    executedAt: o.executedAt == null ? null : toMicros(o.executedAt!),
    revertedAt: o.revertedAt == null ? null : toMicros(o.revertedAt!),
  );

  static Operation _toModel(OperationRow row) => Operation(
    id: OperationId(row.id),
    sessionId: SessionId(row.sessionId),
    seq: row.seq,
    type: OperationType.values.byName(row.type),
    sourceId: SourceId(row.sourceId),
    fromPath: row.fromPath == null ? null : LogicalPath(row.fromPath!),
    toPath: row.toPath == null ? null : LogicalPath(row.toPath!),
    fingerprint: row.fingerprintSize == null
        ? null
        : Fingerprint(
            size: row.fingerprintSize!,
            modifiedAt: fromMicros(row.fingerprintModifiedAt!),
            fullHash: row.fingerprintFullHash,
          ),
    quarantineRef: row.quarantineRef == null
        ? null
        : QuarantineRef(row.quarantineRef!),
    reason: row.reason,
    groupKey: row.groupKey,
    status: OperationStatus.values.byName(row.status),
    error: row.error,
    executedAt: fromMicrosOrNull(row.executedAt),
    revertedAt: fromMicrosOrNull(row.revertedAt),
  );
}
