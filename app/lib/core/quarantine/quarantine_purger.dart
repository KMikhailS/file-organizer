import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/session_stats.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/operation_journal.dart';
import 'package:file_organizer/core/ports/session_repository.dart';
import 'package:file_organizer/core/ports/settings_repository.dart';
import 'package:meta/meta.dart';

/// A quarantined file the purge left alone, and why.
@immutable
final class PurgeKept {
  const PurgeKept(this.operation, this.reason);

  final Operation operation;

  final String reason;

  @override
  bool operator ==(Object other) =>
      other is PurgeKept &&
      other.operation == operation &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(operation, reason);

  @override
  String toString() => 'PurgeKept(${operation.id}: $reason)';
}

/// Outcome of a purge.
@immutable
final class PurgeResult {
  PurgeResult({
    required Iterable<Operation> purged,
    required Iterable<PurgeKept> kept,
  }) : purged = List.unmodifiable(purged),
       kept = List.unmodifiable(kept);

  /// Operations whose file is gone for good, marked revertSkipped.
  final List<Operation> purged;

  /// Expired operations left in the quarantine.
  final List<PurgeKept> kept;

  @override
  bool operator ==(Object other) =>
      other is PurgeResult &&
      listEquals(other.purged, purged) &&
      listEquals(other.kept, kept);

  @override
  int get hashCode => Object.hash(Object.hashAll(purged), Object.hashAll(kept));

  @override
  String toString() =>
      'PurgeResult(${purged.length} purged, ${kept.length} kept)';
}

/// Empties the quarantine of files kept longer than the retention period
/// (settings, 30 days by default).
///
/// Only done quarantine operations of finished sessions are purged. Left
/// alone: sources whose system trash empties itself, sources that are not
/// available, sessions not recovered yet, and files whose undo was already
/// tried (the user wanted them back).
///
/// A purged operation becomes revertSkipped with `QuarantinePurged` — the same
/// state an undo gives when it finds the quarantine purged — so the UI knows
/// that undo is no longer possible for it.
final class QuarantinePurger {
  QuarantinePurger({
    required this._journal,
    required this._sessions,
    required this._settings,
    required this._clock,
  });

  final OperationJournal _journal;
  final SessionRepository _sessions;
  final SettingsRepository _settings;
  final Clock _clock;

  /// Purges what expired. [sources] are the available sources by id.
  Future<PurgeResult> purgeExpired(Map<SourceId, FileSource> sources) async {
    final retention = (await _settings.load()).quarantineRetention;
    final cutoff = _clock.now().subtract(retention);
    final purged = <Operation>[];
    final kept = <PurgeKept>[];
    final sessions = <SessionId, CleanupSession?>{};

    for (final op in await _journal.doneQuarantinesBefore(cutoff)) {
      final session = sessions[op.sessionId] ??= await _sessions.byId(
        op.sessionId,
      );
      if (session == null || !session.status.isFinished) {
        kept.add(PurgeKept(op, 'the session has not finished'));
        continue;
      }
      final source = sources[op.sourceId];
      if (source == null) {
        kept.add(PurgeKept(op, 'the source is not available'));
        continue;
      }
      if (source.capabilities.systemPurgesQuarantine) {
        kept.add(PurgeKept(op, 'the system empties this quarantine'));
        continue;
      }
      switch (await source.purgeQuarantined(op.quarantineRef!)) {
        case FileSuccess():
        case FileFailure(error: FileError(kind: FileErrorKind.notFound)):
          final marked = op.markRevertSkipped(error: const QuarantinePurged());
          await _journal.update(marked);
          purged.add(marked);
        case FileFailure(:final error):
          kept.add(PurgeKept(op, 'purge failed: ${error.kind.name}'));
      }
    }

    for (final sessionId in {for (final op in purged) op.sessionId}) {
      final session = sessions[sessionId]!;
      await _sessions.save(
        session.withStats(SessionStats.of(await _journal.bySession(sessionId))),
      );
    }
    return PurgeResult(purged: purged, kept: kept);
  }
}
