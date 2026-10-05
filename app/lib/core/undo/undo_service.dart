import 'dart:async';

import 'package:file_organizer/core/layout/name_allocator.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
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
import 'package:file_organizer/core/undo/undo_types.dart';

/// A running undo.
final class UndoRun {
  UndoRun._(this._progress, this.result, this._cancel);

  final StreamController<UndoEntry> _progress;
  final _CancelFlag _cancel;

  /// The outcome when the undo has stopped.
  final Future<UndoResult> result;

  /// One entry after each operation. Undo does not depend on listeners;
  /// [cancel] stops it.
  Stream<UndoEntry> get progress => _progress.stream;

  /// Stops after the current operation; the session becomes partially
  /// reverted.
  void cancel() => _cancel.requested = true;
}

/// Puts files back where they were before a cleanup.
///
/// Done operations (and ones whose undo was skipped before, for a retry)
/// are undone in reverse order:
///
/// - `move` → moved back, if the file is still where the cleanup put it and
///   has the same size and modification time;
/// - `quarantine` → restored from the quarantine;
/// - `mkdir` → the folder is removed if it is empty;
/// - `addToAlbum` → removed from the album.
///
/// A missing original folder is created again. A taken original place gets
/// a name with the "restored" label instead: nothing is ever overwritten.
/// When the undo is not possible (file missing or changed, quarantine
/// purged, folder not empty), the operation is marked revertSkipped with
/// the reason and the rest goes on.
final class UndoService {
  /// [restoredLabel] comes from the app's localization, like the template
  /// folder names: a file whose place is taken comes back as
  /// `name (<label>).ext`.
  UndoService({
    required this._journal,
    required this._sessions,
    required this._clock,
    required this.restoredLabel,
  }) {
    if (restoredLabel.isEmpty ||
        restoredLabel.contains('/') ||
        restoredLabel.contains('\u0000')) {
      throw ArgumentError.value(restoredLabel, 'restoredLabel');
    }
  }

  final OperationJournal _journal;
  final SessionRepository _sessions;
  final Clock _clock;

  final String restoredLabel;

  /// Gives up looking for a free "restored" name after this many tries.
  static const int maxRestoredSuffix = 1000;

  /// Starts undoing [scope] of the session [sessionId] on [source]. The
  /// source may be omitted only when there is nothing to undo (a session
  /// without operations).
  ///
  /// The result fails with [StateError] if the session is unknown, has not
  /// finished executing (planned, or running and not recovered yet), the
  /// operation of [OneOperation] is not in it, or the source is missing; and
  /// with [ArgumentError] if the session belongs to another source.
  UndoRun start(
    FileSource? source,
    SessionId sessionId, {
    UndoScope scope = const WholeSession(),
  }) {
    // Synchronous delivery, as in the executor: a cancel from a progress
    // handler takes effect before the next operation.
    final progress = StreamController<UndoEntry>.broadcast(sync: true);
    final cancel = _CancelFlag();
    final result = _run(
      source,
      sessionId,
      scope,
      progress,
      cancel,
    ).whenComplete(progress.close);
    return UndoRun._(progress, result, cancel);
  }

  Future<UndoResult> _run(
    FileSource? source,
    SessionId sessionId,
    UndoScope scope,
    StreamController<UndoEntry> progress,
    _CancelFlag cancel,
  ) async {
    var session = await _sessions.byId(sessionId);
    if (session == null) {
      throw StateError('Unknown session $sessionId');
    }
    if (!session.status.isFinished) {
      throw StateError(
        'Session $sessionId is ${session.status.name}; '
        'it must finish (or be recovered) before an undo',
      );
    }

    final all = await _journal.bySession(sessionId, reverse: true);
    if (source != null && all.any((o) => o.sourceId != source.sourceId)) {
      throw ArgumentError.value(source, 'source', 'not the session source');
    }
    final inScope = switch (scope) {
      WholeSession() => all,
      OneGroup(:final groupKey) => [
        for (final op in all)
          if (op.groupKey == groupKey) op,
      ],
      OneOperation(:final operationId) => [
        all.firstWhere(
          (o) => o.id == operationId,
          orElse: () => throw StateError(
            'Operation $operationId is not in session $sessionId',
          ),
        ),
      ],
    };

    final entries = <UndoEntry>[];
    for (final op in inScope) {
      if (cancel.requested) {
        break;
      }
      if (op.status != OperationStatus.done &&
          op.status != OperationStatus.revertSkipped) {
        continue;
      }
      if (source == null) {
        throw StateError('Session $sessionId needs its source to be undone');
      }
      final entry = await _revert(source, op);
      await _journal.update(entry.operation);
      entries.add(entry);
      progress.add(entry);
    }

    if (session.status == SessionStatus.reverted) {
      return UndoResult(session, entries);
    }
    final after = await _journal.bySession(sessionId);
    final remaining = after.any(
      (o) =>
          o.status == OperationStatus.done ||
          o.status == OperationStatus.revertSkipped,
    );
    session = session
        .withStats(SessionStats.of(after))
        .transitionTo(
          remaining ? SessionStatus.partiallyReverted : SessionStatus.reverted,
        );
    await _sessions.save(session);
    return UndoResult(session, entries);
  }

  Future<UndoEntry> _revert(FileSource source, Operation op) async {
    switch (op.type) {
      case OperationType.mkdir:
        return switch (await source.removeEmptyDir(op.toPath!)) {
          FileSuccess() => _reverted(op),
          FileFailure(error: FileError(kind: FileErrorKind.notFound)) =>
            _reverted(op),
          FileFailure(error: FileError(kind: FileErrorKind.notEmpty)) => _skip(
            op,
            const FolderNotEmpty(),
          ),
          FileFailure(:final error) => _skip(op, _problem(error)),
        };

      case OperationType.addToAlbum:
        return switch (await source.removeFromAlbum(op.fromPath!)) {
          FileSuccess() => _reverted(op),
          FileFailure(error: FileError(kind: FileErrorKind.notFound)) =>
            _reverted(op),
          FileFailure(:final error) => _skip(op, _problem(error)),
        };

      case OperationType.move:
        final at = op.toPath!;
        final problem = await _checkMoved(source, op, at);
        if (problem != null) {
          return _skip(op, problem);
        }
        final (destination, destinationProblem) = await _destination(
          source,
          op.fromPath!,
        );
        if (destination == null) {
          return _skip(op, destinationProblem!);
        }
        return switch (await source.move(at, destination)) {
          FileSuccess() => _reverted(op, destination),
          FileFailure(:final error) => _skip(op, _problem(error)),
        };

      case OperationType.quarantine:
        final ref = op.quarantineRef;
        if (ref == null) {
          return _skip(op, const CannotRestore());
        }
        final (destination, destinationProblem) = await _destination(
          source,
          op.fromPath!,
        );
        if (destination == null) {
          return _skip(op, destinationProblem!);
        }
        return switch (await source.restore(ref, destination)) {
          FileSuccess() => _reverted(op, destination),
          FileFailure(error: FileError(kind: FileErrorKind.notFound)) => _skip(
            op,
            const QuarantinePurged(),
          ),
          FileFailure(error: FileError(kind: FileErrorKind.unsupported)) =>
            _skip(op, const CannotRestore()),
          FileFailure(:final error) => _skip(op, _problem(error)),
        };
    }
  }

  /// Why the moved file cannot be moved back, or `null`.
  Future<OperationProblem?> _checkMoved(
    FileSource source,
    Operation op,
    LogicalPath at,
  ) async {
    switch (await source.stat(at)) {
      case FileFailure(:final error):
        return error.kind == FileErrorKind.notFound
            ? const NotWhereCleanupPutIt()
            : _problem(error);
      case FileSuccess(value: final stat):
        if (!stat.isFile) {
          return const NotAFile();
        }
        final expected = op.fingerprint!;
        if (stat.size != expected.size ||
            stat.modifiedAt != expected.modifiedAt) {
          return const FileChanged();
        }
        return null;
    }
  }

  /// Where a file goes back to: [original], or a "restored" name next to it
  /// if that is taken. Missing parent folders are created. Returns the path,
  /// or `null` and the problem.
  Future<(LogicalPath?, OperationProblem?)> _destination(
    FileSource source,
    LogicalPath original,
  ) async {
    final chain = <LogicalPath>[];
    for (var f = original.parent!; !f.isRoot; f = f.parent!) {
      chain.add(f);
    }
    for (final folder in chain.reversed) {
      switch (await source.stat(folder)) {
        case FileSuccess(value: final stat) when stat.isDirectory:
          continue;
        case FileSuccess():
          return (null, FolderReplacedByFile(folder));
        case FileFailure(error: FileError(kind: FileErrorKind.notFound)):
          if (await source.mkdir(folder) case FileFailure(:final error)) {
            return (null, _problem(error, path: folder));
          }
        case FileFailure(:final error):
          return (null, _problem(error, path: folder));
      }
    }

    final (stem, extension) = NameAllocator.split(original.name);
    final dotExtension = extension.isEmpty ? '' : '.$extension';
    for (var n = 0; n <= maxRestoredSuffix; n++) {
      final candidate = switch (n) {
        0 => original,
        1 => original.parent!.child('$stem ($restoredLabel)$dotExtension'),
        _ => original.parent!.child('$stem ($restoredLabel $n)$dotExtension'),
      };
      switch (await source.exists(candidate)) {
        case FileSuccess(value: false):
          return (candidate, null);
        case FileSuccess(value: true):
          continue;
        case FileFailure(:final error):
          return (null, _problem(error, path: candidate));
      }
    }
    return (null, NoFreeName(original));
  }

  UndoEntry _reverted(Operation op, [LogicalPath? destination]) => UndoEntry(
    op.markReverted(at: _clock.now()),
    restoredAs: destination != null && destination != op.fromPath
        ? destination
        : null,
  );

  UndoEntry _skip(Operation op, OperationProblem problem) =>
      UndoEntry(op.markRevertSkipped(error: problem));

  static OperationProblem _problem(FileError error, {LogicalPath? path}) =>
      FileSystemError(error.kind, path: path, detail: error.message);
}

final class _CancelFlag {
  bool requested = false;
}
