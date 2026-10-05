import 'dart:async';

import 'package:file_organizer/core/executor/execution_progress.dart';
import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/duplicate_group.dart';
import 'package:file_organizer/core/model/fingerprint.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_status.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/plan.dart';
import 'package:file_organizer/core/model/session_stats.dart';
import 'package:file_organizer/core/model/session_status.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/id_generator.dart';
import 'package:file_organizer/core/ports/operation_journal.dart';
import 'package:file_organizer/core/ports/session_repository.dart';

/// A running execution of a plan.
final class ExecutionRun {
  ExecutionRun._(this.sessionId, this._progress, this.result, this._cancel);

  /// The session created for this execution.
  final SessionId sessionId;

  final StreamController<ExecutionProgress> _progress;

  final _CancelFlag _cancel;

  /// The session when execution has stopped: completed or cancelled.
  final Future<CleanupSession> result;

  /// Progress after each operation. Execution does not depend on listeners:
  /// cancelling a subscription does not stop it, [cancel] does.
  Stream<ExecutionProgress> get progress => _progress.stream;

  /// Stops after the current operation; the session becomes cancelled.
  void cancel() => _cancel.requested = true;
}

/// Executes the approved operations of a plan, safely and with a journal.
///
/// For each operation, in plan order:
/// 1. it is written to the journal as pending;
/// 2. it is skipped if it depends on a folder that could not be created;
/// 3. the file is checked: a moved file must still have the size and
///    modification time it had at scan time; a duplicate must still be one —
///    the full hashes of the copy and of the kept file are computed again,
///    never taken from the cache. Otherwise the operation is skipped;
/// 4. it is executed through the file source and journaled as done or
///    failed.
///
/// A failure does not stop the cleanup. A folder that already exists is
/// skipped (not undone later) and the moves into it go on. Unapproved
/// operations are neither journaled nor executed.
final class Executor {
  Executor({
    required this._journal,
    required this._sessions,
    required this._clock,
    required this._ids,
  });

  final OperationJournal _journal;
  final SessionRepository _sessions;
  final Clock _clock;
  final IdGenerator _ids;

  /// Starts executing [plan] on [source] in a new session.
  ///
  /// Throws [ArgumentError] right away if the plan has operations of
  /// another source.
  ExecutionRun start(FileSource source, Plan plan) {
    if (plan.operations.any((o) => o.sourceId != source.sourceId)) {
      throw ArgumentError.value(
        plan,
        'plan',
        'has operations of another source',
      );
    }
    final sessionId = SessionId(_ids.newId());
    // Synchronous delivery: a listener sees each operation before the next
    // one starts, so a cancel from a progress handler takes effect at once.
    final progress = StreamController<ExecutionProgress>.broadcast(sync: true);
    final cancel = _CancelFlag();
    final result = _run(
      source,
      plan,
      sessionId,
      progress,
      cancel,
    ).whenComplete(progress.close);
    return ExecutionRun._(sessionId, progress, result, cancel);
  }

  Future<CleanupSession> _run(
    FileSource source,
    Plan plan,
    SessionId sessionId,
    StreamController<ExecutionProgress> progress,
    _CancelFlag cancel,
  ) async {
    var session = CleanupSession(
      id: sessionId,
      startedAt: _clock.now(),
      status: SessionStatus.planned,
      stats: SessionStats.empty,
    );
    await _sessions.save(session);
    session = session.transitionTo(SessionStatus.running);
    await _sessions.save(session);

    final operations = plan.approvedOperations;
    final context = _Context(source, sessionId, {
      for (final group in plan.duplicateGroups)
        for (final extra in group.extras) extra.path: group,
    });
    var done = 0;
    var skipped = 0;
    var failed = 0;

    for (var seq = 0; seq < operations.length && !cancel.requested; seq++) {
      final pending = Operation.pending(
        id: OperationId(_ids.newId()),
        sessionId: sessionId,
        seq: seq,
        planned: operations[seq],
      );
      await _journal.append(pending);
      final (finished, blocksFolder) = await _perform(pending, context);
      await _journal.update(finished);

      switch (finished.status) {
        case OperationStatus.done:
          done++;
          if (finished.type == OperationType.move) {
            context.movedTo[finished.fromPath!] = finished.toPath!;
          }
        case OperationStatus.skipped:
          skipped++;
        case OperationStatus.failed:
          failed++;
        case OperationStatus.pending ||
            OperationStatus.reverted ||
            OperationStatus.revertSkipped:
          throw StateError('unexpected status ${finished.status}');
      }
      if (blocksFolder) {
        context.failedFolders[finished.toPath!.value.toLowerCase()] =
            finished.toPath!;
      }
      progress.add(
        ExecutionProgress(
          sessionId: sessionId,
          total: operations.length,
          done: done,
          skipped: skipped,
          failed: failed,
          last: finished,
        ),
      );
    }

    final stats = SessionStats.of(await _journal.bySession(sessionId));
    session = session
        .withStats(stats)
        .transitionTo(
          cancel.requested ? SessionStatus.cancelled : SessionStatus.completed,
          finishedAt: _clock.now(),
        );
    await _sessions.save(session);
    return session;
  }

  /// Executes one journaled operation. Returns it finished, and whether it
  /// is a folder that later operations cannot use.
  Future<(Operation, bool)> _perform(Operation op, _Context context) async {
    final blocker = context.blocker(op);
    if (blocker != null) {
      return (_skip(op, DependsOnMissingFolder(blocker)), true);
    }

    switch (op.type) {
      case OperationType.mkdir:
        final to = op.toPath!;
        switch (await context.source.mkdir(to)) {
          case FileSuccess():
            return (op.markDone(at: _clock.now()), false);
          case FileFailure(:final error):
            if (error.kind == FileErrorKind.targetExists) {
              final stat = await context.source.stat(to);
              if (stat case FileSuccess(value: final s) when s.isDirectory) {
                return (_skip(op, const FolderExists()), false);
              }
            }
            return (_fail(op, error), true);
        }

      case OperationType.move:
        final problem = await _checkUnchanged(context, op);
        if (problem != null) {
          return (_skip(op, problem), false);
        }
        return switch (await context.source.move(op.fromPath!, op.toPath!)) {
          FileSuccess() => (op.markDone(at: _clock.now()), false),
          FileFailure(:final error) => (_fail(op, error), false),
        };

      case OperationType.quarantine || OperationType.addToAlbum:
        final problem =
            await _checkUnchanged(context, op) ??
            await _checkDuplicate(context, op);
        if (problem != null) {
          return (_skip(op, problem), false);
        }
        if (op.type == OperationType.addToAlbum) {
          return switch (await context.source.addToAlbum(op.fromPath!)) {
            FileSuccess() => (op.markDone(at: _clock.now()), false),
            FileFailure(:final error) => (_fail(op, error), false),
          };
        }
        return switch (await context.source.quarantine(
          op.fromPath!,
          context.sessionId,
        )) {
          FileSuccess(value: final ref) => (
            op.markDone(at: _clock.now(), quarantineRef: ref),
            false,
          ),
          FileFailure(:final error) => (_fail(op, error), false),
        };
    }
  }

  /// Why the file of [op] cannot be used as planned, or `null`.
  Future<OperationProblem?> _checkUnchanged(
    _Context context,
    Operation op,
  ) async {
    final from = op.fromPath!;
    final Fingerprint expected = op.fingerprint!;
    switch (await context.source.stat(from)) {
      case FileFailure(:final error):
        return error.kind == FileErrorKind.notFound
            ? const FileGone()
            : _problem(error);
      case FileSuccess(value: final stat):
        if (!stat.isFile) {
          return const NotAFile();
        }
        if (stat.size != expected.size ||
            stat.modifiedAt != expected.modifiedAt) {
          return const FileChanged();
        }
        return null;
    }
  }

  /// Why [op] is not a verified duplicate, or `null`. Hashes are computed
  /// again: the cached ones may be stale.
  Future<OperationProblem?> _checkDuplicate(
    _Context context,
    Operation op,
  ) async {
    final group = context.groups[op.fromPath!];
    if (group == null) {
      return const NotADuplicate();
    }
    switch (await context.source.fullHash(op.fromPath!)) {
      case FileFailure(:final error):
        return _problem(error);
      case FileSuccess(:final value) when value != group.fullHash:
        return const NotADuplicate();
      case FileSuccess():
        break;
    }
    final keeper = context.movedTo[group.keeper.path] ?? group.keeper.path;
    switch (await context.source.fullHash(keeper)) {
      case FileFailure(error: FileError(kind: FileErrorKind.notFound)):
        return KeeperChanged(keeper);
      case FileFailure(:final error):
        return _problem(error, path: keeper);
      case FileSuccess(:final value) when value != group.fullHash:
        return KeeperChanged(keeper);
      case FileSuccess():
        return null;
    }
  }

  Operation _skip(Operation op, OperationProblem problem) =>
      op.markSkipped(at: _clock.now(), error: problem);

  Operation _fail(Operation op, FileError error) =>
      op.markFailed(at: _clock.now(), error: _problem(error));

  static OperationProblem _problem(FileError error, {LogicalPath? path}) =>
      FileSystemError(error.kind, path: path, detail: error.message);
}

final class _CancelFlag {
  bool requested = false;
}

/// State of one execution.
final class _Context {
  _Context(this.source, this.sessionId, this.groups);

  final FileSource source;
  final SessionId sessionId;

  /// Duplicate groups by the path of each extra copy.
  final Map<LogicalPath, DuplicateGroup> groups;

  /// Where files moved in this session went.
  final Map<LogicalPath, LogicalPath> movedTo = {};

  /// Folders that could not be created, by their lower-case path.
  final Map<String, LogicalPath> failedFolders = {};

  /// The missing folder [op] depends on, or `null`.
  LogicalPath? blocker(Operation op) {
    final to = op.toPath;
    if (to == null || failedFolders.isEmpty) {
      return null;
    }
    final parent = to.parent!.value.toLowerCase();
    for (final MapEntry(key: lower, value: folder) in failedFolders.entries) {
      if (parent == lower || parent.startsWith('$lower/')) {
        return folder;
      }
    }
    return null;
  }
}
