import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/converters.dart';

final class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(CleanupSession session) => _db.transaction(() async {
    final stored = await byId(session.id);
    if (stored != null) {
      RepositoryRules.checkSessionReplace(stored, session);
    }
    final s = session.stats;
    await _db
        .into(_db.sessions)
        .insertOnConflictUpdate(
          SessionRow(
            id: session.id.value,
            startedAt: toMicros(session.startedAt),
            finishedAt: session.finishedAt == null
                ? null
                : toMicros(session.finishedAt!),
            status: session.status.name,
            statTotal: s.total,
            statDone: s.done,
            statFailed: s.failed,
            statSkipped: s.skipped,
            statReverted: s.reverted,
            statRevertSkipped: s.revertSkipped,
            statRemovedBytes: s.removedBytes,
          ),
        );
  });

  @override
  Future<CleanupSession?> byId(SessionId id) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<CleanupSession>> all() async =>
      _newestFirst(await _db.select(_db.sessions).get());

  @override
  Future<List<CleanupSession>> byStatus(SessionStatus status) async =>
      _newestFirst(
        await (_db.select(
          _db.sessions,
        )..where((t) => t.status.equals(status.name))).get(),
      );

  static List<CleanupSession> _newestFirst(List<SessionRow> rows) =>
      rows.map(_toModel).toList()..sort((a, b) {
        final byTime = b.startedAt.compareTo(a.startedAt);
        return byTime != 0 ? byTime : b.id.value.compareTo(a.id.value);
      });

  static CleanupSession _toModel(SessionRow row) => CleanupSession(
    id: SessionId(row.id),
    startedAt: fromMicros(row.startedAt),
    finishedAt: fromMicrosOrNull(row.finishedAt),
    status: SessionStatus.values.byName(row.status),
    stats: SessionStats(
      total: row.statTotal,
      done: row.statDone,
      failed: row.statFailed,
      skipped: row.statSkipped,
      reverted: row.statReverted,
      revertSkipped: row.statRevertSkipped,
      removedBytes: row.statRemovedBytes,
    ),
  );
}
