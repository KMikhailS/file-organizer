import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/session_stats.dart';
import 'package:file_organizer/core/model/session_status.dart';
import 'package:meta/meta.dart';

/// One cleanup: a plan, its execution and possibly its undo.
@immutable
final class CleanupSession {
  /// Creates a session. Dates are stored in UTC.
  ///
  /// Throws [ArgumentError] if [finishedAt] is set for a session that has not
  /// finished executing, is missing for one that has, or is before
  /// [startedAt].
  CleanupSession({
    required this.id,
    required DateTime startedAt,
    required this.status,
    required this.stats,
    DateTime? finishedAt,
  }) : startedAt = startedAt.toUtc(),
       finishedAt = finishedAt?.toUtc() {
    if ((finishedAt == null) == status.isFinished) {
      throw ArgumentError.value(
        finishedAt,
        'finishedAt',
        'must be set exactly when execution has finished (status: '
            '${status.name})',
      );
    }
    if (finishedAt != null && finishedAt.isBefore(startedAt)) {
      throw ArgumentError.value(finishedAt, 'finishedAt', 'before startedAt');
    }
  }

  final SessionId id;

  /// In UTC.
  final DateTime startedAt;

  /// When execution finished, in UTC.
  final DateTime? finishedAt;

  final SessionStatus status;

  final SessionStats stats;

  /// A copy in status [next].
  ///
  /// [finishedAt] is required when execution finishes (moving from planned
  /// or running to completed, failed or cancelled) and must be omitted
  /// otherwise; the finish time is kept through undo.
  ///
  /// Throws [StateError] if the transition is not allowed (see
  /// [SessionStatus]).
  CleanupSession transitionTo(SessionStatus next, {DateTime? finishedAt}) {
    if (!status.canTransitionTo(next)) {
      throw StateError(
        'Session $id: cannot go from ${status.name} to ${next.name}',
      );
    }
    final finishes = !status.isFinished && next.isFinished;
    if (finishes != (finishedAt != null)) {
      throw ArgumentError.value(
        finishedAt,
        'finishedAt',
        finishes
            ? 'required when execution finishes'
            : 'only when execution finishes',
      );
    }
    return CleanupSession(
      id: id,
      startedAt: startedAt,
      status: next,
      stats: stats,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  /// A copy with [stats] replaced.
  CleanupSession withStats(SessionStats stats) => CleanupSession(
    id: id,
    startedAt: startedAt,
    status: status,
    stats: stats,
    finishedAt: finishedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is CleanupSession &&
      other.id == id &&
      other.startedAt == startedAt &&
      other.finishedAt == finishedAt &&
      other.status == status &&
      other.stats == stats;

  @override
  int get hashCode => Object.hash(id, startedAt, finishedAt, status, stats);

  @override
  String toString() =>
      'CleanupSession($id, ${status.name}, started: '
      '${startedAt.toIso8601String()}, $stats)';
}
