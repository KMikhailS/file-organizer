import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_status.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:meta/meta.dart';

/// One cleanup in the history, with its groups and files
/// (`docs/stage2_android.md`, section 9, screen 7).
@immutable
final class SessionDetail {
  SessionDetail({required this.session, required Iterable<HistoryGroup> groups})
    : groups = List.unmodifiable(groups);

  final CleanupSession session;

  /// In plan order; groups with nothing but folders are left out.
  final List<HistoryGroup> groups;

  /// Files that an undo of the whole cleanup would bring back.
  int get undoable => groups.fold(0, (n, g) => n + g.undoable);

  /// Files whose quarantine was purged: they cannot come back.
  int get purged => groups.fold(0, (n, g) => n + g.purged);
}

/// A plan group of a past cleanup.
@immutable
final class HistoryGroup {
  HistoryGroup({
    required this.key,
    required this.kind,
    required Iterable<HistoryFile> files,
  }) : files = List.unmodifiable(files);

  /// The group key (for the undo command).
  final String key;
  final PlanGroupKind kind;
  final List<HistoryFile> files;

  int get undoable => files.where((f) => f.undoable).length;
  int get purged => files.where((f) => f.purged).length;
}

/// A file operation of a past cleanup.
@immutable
final class HistoryFile {
  const HistoryFile({
    required this.operationId,
    required this.type,
    required this.from,
    required this.to,
    required this.status,
    required this.problem,
  });

  final OperationId operationId;
  final OperationType type;
  final LogicalPath from;

  /// Where a move went; `null` for the quarantine.
  final LogicalPath? to;
  final OperationStatus status;

  /// Why it failed, was skipped or was not undone.
  final OperationProblem? problem;

  /// The quarantine was purged: the file cannot come back.
  bool get purged => problem is QuarantinePurged;

  /// An undo would try to bring it back: it was done, or an earlier undo
  /// could not and may succeed now (unless the quarantine was purged).
  bool get undoable =>
      status == OperationStatus.done ||
      (status == OperationStatus.revertSkipped && !purged);
}
