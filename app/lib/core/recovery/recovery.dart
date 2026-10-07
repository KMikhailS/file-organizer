import 'dart:math';

import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/fingerprint.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_reason.dart';
import 'package:file_organizer/core/model/operation_status.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/session_stats.dart';
import 'package:file_organizer/core/model/session_status.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/file_stat.dart';
import 'package:file_organizer/core/ports/id_generator.dart';
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
/// An adapter without a no-replace rename reserves the target name with an
/// empty placeholder first (decision A.5). A crash between the two steps
/// leaves the file at its source and the placeholder at the target. So for a
/// move that did not happen, an empty file at the target that changed no
/// earlier than the session started ([placeholderTolerance] earlier at most)
/// is put into the quarantine: a new journaled operation (pending first)
/// with the reason [MovePlaceholder]. Undo never restores it.
///
/// "Failed" here means "needs attention". The session is then closed as
/// failed and can be undone.
final class Recovery {
  Recovery({
    required this._journal,
    required this._sessions,
    required this._clock,
    required this._ids,
  });

  final OperationJournal _journal;
  final SessionRepository _sessions;
  final Clock _clock;
  final IdGenerator _ids;

  /// How much earlier than the session start a placeholder may look
  /// modified: file systems store times with a coarser resolution.
  static const Duration placeholderTolerance = Duration(seconds: 2);

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
    var nextSeq = ops.isEmpty ? 0 : ops.map((o) => o.seq).reduce(max) + 1;
    for (final op in pending) {
      final checked = await _check(source!, op);
      await _journal.update(checked);
      recovered.add(checked);
      // The move is journaled as final before its placeholder operation is
      // added, so a later recovery never sees the move pending again and
      // never adds a second one; it finishes the pending placeholder
      // operation instead (see _check).
      if (op.type == OperationType.move &&
          checked.status == OperationStatus.skipped) {
        final cleared = await _quarantinePlaceholder(
          source,
          session,
          checked,
          nextSeq,
        );
        if (cleared != null) {
          recovered.add(cleared);
          nextSeq++;
        }
      }
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
          case FileSuccess(value: final s)
              when s.isFile && s.size == 0 && op.reason is MovePlaceholder:
            // Recovery's own operation, interrupted before its effect: the
            // placeholder is still there, so finish clearing it.
            return _quarantine(source, op);
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

  /// Puts the empty placeholder at the target of the interrupted [move]
  /// into the quarantine, journaled as operation number [seq]. Returns that
  /// operation, or `null` if there is no placeholder to clear.
  Future<Operation?> _quarantinePlaceholder(
    FileSource source,
    CleanupSession session,
    Operation move,
    int seq,
  ) async {
    if (!source.capabilities.canQuarantine) {
      return null;
    }
    final target = move.toPath!;
    final earliest = session.startedAt.subtract(placeholderTolerance);
    final FileStat stat;
    switch (await source.stat(target)) {
      case FileSuccess(:final value)
          when value.isFile &&
              value.size == 0 &&
              !value.modifiedAt.isBefore(earliest):
        stat = value;
      case _:
        return null;
    }
    final pending = Operation(
      id: OperationId(_ids.newId()),
      sessionId: move.sessionId,
      seq: seq,
      type: OperationType.quarantine,
      sourceId: move.sourceId,
      fromPath: target,
      toPath: null,
      fingerprint: Fingerprint(size: 0, modifiedAt: stat.modifiedAt),
      reason: MovePlaceholder(move.fromPath!),
      groupKey: move.groupKey,
      status: OperationStatus.pending,
    );
    await _journal.append(pending);
    final executed = await _quarantine(source, pending);
    await _journal.update(executed);
    return executed;
  }

  /// Executes the pending quarantine [op] of a placeholder.
  Future<Operation> _quarantine(FileSource source, Operation op) async {
    final path = op.fromPath!;
    return switch (await source.quarantine(path, op.sessionId)) {
      FileSuccess(:final value) => op.markDone(
        at: _clock.now(),
        quarantineRef: value,
      ),
      FileFailure(:final error) => op.markFailed(
        at: _clock.now(),
        error: FileSystemError(error.kind, path: path, detail: error.message),
      ),
    };
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
