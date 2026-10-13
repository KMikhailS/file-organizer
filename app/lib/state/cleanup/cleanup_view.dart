import 'package:file_organizer/core/model/classification_reason.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_reason.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/session_stats.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:meta/meta.dart';

/// What the cleanup screens show: the state of the workflow turned into the
/// terms of the screens (`docs/stage2_android.md`, 5.19). The UI sees only
/// these models and `core/model`, never the workflow itself.
@immutable
sealed class CleanupView {
  const CleanupView();
}

/// Nothing going on: the home screen.
final class AtHome extends CleanupView {
  const AtHome();
}

/// How a cleanup or an undo ended.
enum ResultKind {
  /// Every approved operation was executed (some may have failed).
  completed,

  /// The user stopped the execution.
  cancelled,

  /// Every executed operation was undone.
  reverted,

  /// Some operations could not be undone, or the undo was stopped.
  partiallyReverted,
}

/// A cleanup or an undo just ended: what happened, until the user closes
/// it. Its problems come from the journal (`sessionProblemsProvider`).
final class CleanupResult extends CleanupView {
  CleanupResult({
    required this.kind,
    required Iterable<SessionId> sessions,
    required this.totals,
  }) : sessions = List.unmodifiable(sessions);

  final ResultKind kind;

  /// The sessions of the run, in order.
  final List<SessionId> sessions;

  /// Their statistics added up.
  final SessionStats totals;

  /// Whether "Undo the cleanup" applies: something is left to undo.
  bool get canUndo => kind != ResultKind.reverted;
}

enum ProgressStage { scanning, analyzing, executing, undoing }

/// Work in progress.
final class InProgress extends CleanupView {
  const InProgress({
    required this.stage,
    required this.done,
    required this.total,
    required this.sourceIndex,
    required this.sourceCount,
    required this.cancelling,
  });

  final ProgressStage stage;

  /// Files seen while scanning, operations handled while executing or
  /// undoing, size buckets checked while analyzing.
  final int done;

  /// What [done] counts up to; 0 when unknown (scanning, undoing).
  final int total;

  /// Source [sourceIndex] (from 0) of [sourceCount] while scanning and
  /// analyzing; 0 of 1 otherwise.
  final int sourceIndex;
  final int sourceCount;

  /// "Cancel" was asked for; the work stops at the next safe point.
  final bool cancelling;
}

/// The plan, for review and approval.
final class PlanReview extends CleanupView {
  PlanReview({
    required Iterable<SourcePlanView> sources,
    Iterable<SourceId> unavailableSources = const [],
    required this.approvedFiles,
    required this.approvedBytes,
  }) : sources = List.unmodifiable(sources),
       unavailableSources = List.unmodifiable(unavailableSources);

  final List<SourcePlanView> sources;

  /// Enabled sources that could not be opened and were not scanned.
  final List<SourceId> unavailableSources;

  /// Files the approved operations act on, and the bytes they free.
  final int approvedFiles;
  final int approvedBytes;

  /// Nothing to do anywhere.
  bool get isEmpty => sources.every((s) => s.groups.isEmpty);

  /// Whether "Apply" does anything.
  bool get canApply => approvedFiles > 0;
}

/// The pipeline could not make a plan; [reason] is technical.
final class PlanFailed extends CleanupView {
  const PlanFailed(this.reason);

  final String reason;
}

/// Sessions a crash interrupted were recovered at start-up: the user
/// finishes the job (a new plan), undoes them, or decides later.
final class InterruptedCleanup extends CleanupView {
  InterruptedCleanup({
    required this.sessions,
    required this.operations,
    required Iterable<ProblemView> problems,
    required this.unavailable,
  }) : problems = List.unmodifiable(problems);

  /// Sessions recovered (each closed as failed, each can be undone).
  final int sessions;

  /// Operations that were in flight and are now sorted out.
  final int operations;

  /// What recovery could not sort out cleanly; "needs attention" first.
  final List<ProblemView> problems;

  /// Interrupted sessions whose storage is not available now.
  final int unavailable;
}

/// An operation that failed, was skipped or could not be undone.
@immutable
final class ProblemView {
  const ProblemView({
    required this.type,
    required this.path,
    required this.problem,
  });

  final OperationType type;

  /// The file (or the folder of a mkdir).
  final LogicalPath path;
  final OperationProblem problem;

  /// Recovery could not sort it out: the user should look.
  bool get needsAttention => problem is NeedsAttention;
}

/// The plan of one source.
@immutable
final class SourcePlanView {
  SourcePlanView({
    required this.source,
    required Iterable<PlanGroupView> groups,
    Iterable<UnresolvedFile> unresolved = const [],
    this.untouchedCopies = 0,
    Iterable<LogicalPath> inaccessibleFolders = const [],
    Iterable<LogicalPath> unhashedFiles = const [],
  }) : groups = List.unmodifiable(groups),
       unresolved = List.unmodifiable(unresolved),
       inaccessibleFolders = List.unmodifiable(inaccessibleFolders),
       unhashedFiles = List.unmodifiable(unhashedFiles);

  final Source source;

  /// In plan order; groups with nothing but folders are left out.
  final List<PlanGroupView> groups;

  /// Files left in place because the rules are not sure.
  final List<UnresolvedFile> unresolved;

  /// Extra copies in the user's own folders: shown, never touched.
  final int untouchedCopies;

  /// Folders the scan could not read.
  final List<LogicalPath> inaccessibleFolders;

  /// Files that could not be hashed: their duplicates are unknown.
  final List<LogicalPath> unhashedFiles;
}

/// What a plan group does.
@immutable
sealed class PlanGroupKind {
  const PlanGroupKind();
}

/// Extra copies of duplicates go to the quarantine.
final class DuplicatesGroup extends PlanGroupKind {
  const DuplicatesGroup();
}

/// Files move into [folder] (a template folder, maybe with its year).
final class MoveGroup extends PlanGroupKind {
  const MoveGroup(this.folder);

  final LogicalPath folder;
}

/// Whether the files of a group are approved.
enum Approval { all, some, none }

/// A group of the plan, approved as a whole or file by file.
@immutable
final class PlanGroupView {
  PlanGroupView({
    required this.key,
    required this.kind,
    required this.bytes,
    required Iterable<OperationView> files,
  }) : files = List.unmodifiable(files);

  /// The group key of the plan (for the approval commands).
  final String key;
  final PlanGroupKind kind;

  /// Bytes freed by the group (duplicates); 0 for moves.
  final int bytes;

  /// The file operations; the folders they need follow their approval.
  final List<OperationView> files;

  Approval get approval {
    final approved = files.where((f) => f.approved).length;
    return approved == files.length
        ? Approval.all
        : approved == 0
        ? Approval.none
        : Approval.some;
  }
}

/// One file operation of the plan.
@immutable
final class OperationView {
  const OperationView({
    required this.index,
    required this.type,
    required this.from,
    required this.to,
    required this.reason,
    required this.approved,
    required this.size,
    required this.media,
  });

  /// Index in the plan's operations (for the approval command).
  final int index;
  final OperationType type;
  final LogicalPath from;

  /// Where a move goes; `null` for the quarantine.
  final LogicalPath? to;
  final OperationReason reason;
  final bool approved;
  final int size;

  /// An image or a video: it may have a thumbnail.
  final bool media;
}

/// A file the rules could not classify.
@immutable
final class UnresolvedFile {
  const UnresolvedFile({
    required this.path,
    required this.size,
    required this.reason,
  });

  final LogicalPath path;
  final int size;
  final ClassificationReason reason;
}
