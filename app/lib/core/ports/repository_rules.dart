import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_status.dart';

/// Consistency rules shared by every repository implementation, so the
/// in-memory and the database repositories enforce exactly the same thing.
/// A violation is a bug in the caller and throws [StateError].
abstract final class RepositoryRules {
  /// [operation] may be appended to the journal: it must be pending.
  /// Uniqueness of the id and of the seq within the session is checked by
  /// the repository.
  static void checkAppend(Operation operation) {
    if (operation.status != OperationStatus.pending) {
      throw StateError(
        'Journal: ${operation.id} must be appended as pending, '
        'not ${operation.status.name}',
      );
    }
  }

  /// [next] may replace [stored] in the journal: everything but the status
  /// and its fields stays, the status makes an allowed transition, and
  /// execution data already recorded is kept.
  static void checkUpdate(Operation stored, Operation next) {
    void fail(String message) =>
        throw StateError('Journal: ${stored.id}: $message');

    if (next.id != stored.id ||
        next.sessionId != stored.sessionId ||
        next.seq != stored.seq ||
        next.type != stored.type ||
        next.sourceId != stored.sourceId ||
        next.fromPath != stored.fromPath ||
        next.toPath != stored.toPath ||
        next.fingerprint != stored.fingerprint ||
        next.reason != stored.reason ||
        next.groupKey != stored.groupKey) {
      fail('only the status and its fields may change');
    }
    if (!stored.status.canTransitionTo(next.status)) {
      fail('cannot go from ${stored.status.name} to ${next.status.name}');
    }
    if (stored.executedAt != null && next.executedAt != stored.executedAt) {
      fail('executedAt must not change once recorded');
    }
    if (stored.quarantineRef != null &&
        next.quarantineRef != stored.quarantineRef) {
      fail('quarantineRef must not change once recorded');
    }
  }

  /// [next] may replace [stored] in the session repository: same start,
  /// same or allowed next status, finish time kept once recorded.
  static void checkSessionReplace(CleanupSession stored, CleanupSession next) {
    void fail(String message) =>
        throw StateError('Sessions: ${stored.id}: $message');

    if (next.startedAt != stored.startedAt) {
      fail('startedAt must not change');
    }
    if (next.status != stored.status &&
        !stored.status.canTransitionTo(next.status)) {
      fail('cannot go from ${stored.status.name} to ${next.status.name}');
    }
    if (stored.finishedAt != null && next.finishedAt != stored.finishedAt) {
      fail('finishedAt must not change once recorded');
    }
  }
}
