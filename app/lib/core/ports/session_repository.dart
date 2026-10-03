import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/session_status.dart';

/// Stores cleanup sessions.
abstract interface class SessionRepository {
  /// Inserts [session] or replaces the stored one with the same id.
  ///
  /// A replacement keeps `startedAt` and either keeps the status or makes an
  /// allowed transition (see [SessionStatus]); otherwise throws
  /// [StateError]: that is a bug in the caller, not an expected outcome.
  Future<void> save(CleanupSession session);

  Future<CleanupSession?> byId(SessionId id);

  /// All sessions, newest first (by `startedAt`, then by id).
  Future<List<CleanupSession>> all();

  /// Sessions in [status], newest first.
  Future<List<CleanupSession>> byStatus(SessionStatus status);
}
