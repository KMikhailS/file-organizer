import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemorySessionRepository implements SessionRepository {
  final Map<SessionId, CleanupSession> _sessions = {};

  @override
  Future<void> save(CleanupSession session) async {
    final stored = _sessions[session.id];
    if (stored != null) {
      RepositoryRules.checkSessionReplace(stored, session);
    }
    _sessions[session.id] = session;
  }

  @override
  Future<CleanupSession?> byId(SessionId id) async => _sessions[id];

  @override
  Future<List<CleanupSession>> all() async => _newestFirst(_sessions.values);

  @override
  Future<List<CleanupSession>> byStatus(SessionStatus status) async =>
      _newestFirst(_sessions.values.where((s) => s.status == status));

  static List<CleanupSession> _newestFirst(Iterable<CleanupSession> sessions) =>
      sessions.toList()..sort((a, b) {
        final byTime = b.startedAt.compareTo(a.startedAt);
        return byTime != 0 ? byTime : b.id.value.compareTo(a.id.value);
      });
}
