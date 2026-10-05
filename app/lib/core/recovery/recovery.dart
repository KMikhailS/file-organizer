import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_status.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/session_stats.dart';
import 'package:file_organizer/core/model/session_status.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/operation_journal.dart';
import 'package:file_organizer/core/ports/session_repository.dart';
import 'package:meta/meta.dart';

/// Outcome of recovering one session.
@immutable
final class RecoveryResult {
  RecoveryResult(this.session, Iterable<Operation> recovered)
    : recovered = List.unmodifiable(recovered);

  /// The session, closed as failed (execution did not finish). It can be
  /// undone; "finish the job" means planning again in a new session.
  final CleanupSession session;

  /// The operations that were pending, now done, skipped or failed.
  final List<Operation> recovered;

  @override
  bool operator ==(Object other) =>
      other is RecoveryResult &&
      other.session == session &&
      listEquals(other.recovered, recovered);

  @override
  int get hashCode => Object.hash(session, Object.hashAll(recovered));

  @override
  String toString() =>
      'RecoveryResult(${session.id}, ${recovered.length} recovered)';
}

/// Brings the journal in line with reality after a crash.
///
/// A session left running has at most a few pending operations: each was
/// journaled but its result was not. Each is checked against the file
/// system:
///
/// | Operation | Check → status |
/// |---|---|
/// | `move` A→B | file still at A → skipped; else at B with the planned size and time → done; else failed |
/// | `mkdir` F | F is a folder → done; else skipped |
/// | `quarantine` A | file still at A → skipped; else found in the quarantine → done with its reference; else failed |
/// | `addToAlbum` A | photo still there → done (undoing it is harmless either way); else failed |
///
/// For a move the source is checked first: a move is atomic, so a file
/// still at its source was not moved, whatever is at the target.
///
/// "Failed" here means "needs attention". The session is then closed as
/// failed and can be undone.
final class Recovery {
  Recovery({
    required this._journal,
    required this._sessions,
    required this._clock,
  });

  final OperationJournal _journal;
  final SessionRepository _sessions;
  final Clock _clock;

  /// Sessions a crash left running, newest first.
  Future<List<CleanupSession>> interruptedSessions() =>
      _sessions.byStatus(SessionStatus.running);

  /// The source the session worked on, or `null` if it has no operations.
  Future<SourceId?> sourceOf(SessionId sessionId) async {
    final ops = await _journal.bySession(sessionId);
    return ops.isEmpty ? null : ops.first.sourceId;
  }

  /// Recovers [sessionId]. [source] must be the session's source; it may be
  /// omitted only when no operation is pending.
  ///
  /// Throws [StateError] if the session is unknown or not running, or if a
  /// pending operation needs a source that was not given; [ArgumentError] if
  /// [source] is not the session's source.
  Future<RecoveryResult> recover(
    SessionId sessionId, {
    FileSource? source,
  }) async {
    final session = await _sessions.byId(sessionId);
    if (session == null) {
      throw StateError('Unknown session $sessionId');
    }
    if (session.status != SessionStatus.running) {
      throw StateError(
        'Session $sessionId is ${session.status.name}, not running',
      );
    }
    final ops = await _journal.bySession(sessionId);
    if (source != null && ops.any((o) => o.sourceId != source.sourceId)) {
      throw ArgumentError.value(source, 'source', 'not the session source');
    }
    final pending = [
      for (final op in ops)
        if (op.status == OperationStatus.pending) op,
    ];
    if (pending.isNotEmpty && source == null) {
      throw StateError(
        'Session $sessionId has pending operations: a source '
        'is needed to check them',
      );
    }

    final recovered = <Operation>[];
    for (final op in pending) {
      final checked = await _check(source!, op);
      await _journal.update(checked);
      recovered.add(checked);
    }

    final closed = session
        .withStats(SessionStats.of(await _journal.bySession(sessionId)))
        .transitionTo(SessionStatus.failed, finishedAt: _clock.now());
    await _sessions.save(closed);
    return RecoveryResult(closed, recovered);
  }

  Future<Operation> _check(FileSource source, Operation op) async {
    switch (op.type) {
      case OperationType.mkdir:
        return switch (await source.stat(op.toPath!)) {
          FileSuccess(value: final s) when s.isDirectory => _done(op),
          FileSuccess() ||
          FileFailure(
            error: FileError(kind: FileErrorKind.notFound),
          ) => _skipped(op),
          FileFailure(:final error) => _attention(
            op,
            AttentionCause.cannotCheck,
            error.kind,
          ),
        };

      case OperationType.move:
        switch (await source.stat(op.fromPath!)) {
          case FileSuccess(value: final s) when s.isFile:
            return _skipped(op);
          case FileSuccess() ||
              FileFailure(error: FileError(kind: FileErrorKind.notFound)):
            break;
          case FileFailure(:final error):
            return _attention(op, AttentionCause.cannotCheck, error.kind);
        }
        final expected = op.fingerprint!;
        return switch (await source.stat(op.toPath!)) {
          FileSuccess(value: final s)
              when s.isFile &&
                  s.size == expected.size &&
                  s.modifiedAt == expected.modifiedAt =>
            _done(op),
          _ => _attention(op, AttentionCause.fileLost),
        };

      case OperationType.quarantine:
        switch (await source.stat(op.fromPath!)) {
          case FileSuccess(value: final s) when s.isFile:
            return _skipped(op);
          case FileSuccess() ||
              FileFailure(error: FileError(kind: FileErrorKind.notFound)):
            break;
          case FileFailure(:final error):
            return _attention(op, AttentionCause.cannotCheck, error.kind);
        }
        return switch (await source.findQuarantined(
          op.sessionId,
          op.fromPath!,
        )) {
          FileSuccess(value: final ref?) => op.markDone(
            at: _clock.now(),
            quarantineRef: ref,
          ),
          FileSuccess() => _attention(op, AttentionCause.fileLost),
          FileFailure(:final error) => _attention(
            op,
            AttentionCause.cannotSearchQuarantine,
            error.kind,
          ),
        };

      case OperationType.addToAlbum:
        return switch (await source.stat(op.fromPath!)) {
          FileSuccess(value: final s) when s.isFile => _done(op),
          _ => _attention(op, AttentionCause.fileLost),
        };
    }
  }

  Operation _done(Operation op) => op.markDone(at: _clock.now());

  Operation _skipped(Operation op) =>
      op.markSkipped(at: _clock.now(), error: const InterruptedOperation());

  Operation _attention(
    Operation op,
    AttentionCause cause, [
    FileErrorKind? errorKind,
  ]) => op.markFailed(
    at: _clock.now(),
    error: NeedsAttention(cause, errorKind: errorKind),
  );
}
