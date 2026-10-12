import 'package:file_organizer/core/model/classification_reason.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation_reason.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:meta/meta.dart';

/// What the cleanup screens show: the state of the workflow turned into the
/// terms of the screens (`docs/stage2_android.md`, 5.19). The UI sees only
/// these models and `core/model`, never the workflow itself.
@immutable
sealed class CleanupView {
  const CleanupView();
}

/// Nothing to show beyond the home screen: idle, or a cleanup or undo
/// finished (its result is on the home screen).
final class AtHome extends CleanupView {
  const AtHome();
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

/// Sessions a crash interrupted were recovered at start-up. TEMPORARY
/// screen until task 14.
final class InterruptedCleanup extends CleanupView {
  const InterruptedCleanup({
    required this.recovered,
    required this.unavailable,
  });

  final int recovered;
  final int unavailable;
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
