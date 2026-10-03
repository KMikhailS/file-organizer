import 'package:file_organizer/core/dedupe/dedupe_event.dart';
import 'package:file_organizer/core/executor/execution_progress.dart';
import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/plan.dart';
import 'package:file_organizer/core/model/plan_summary.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/core/recovery/recovery.dart';
import 'package:file_organizer/core/scan/scan_summary.dart';
import 'package:meta/meta.dart';

/// The plan of one source, with what the UI shows next to it.
@immutable
final class SourcePlan {
  SourcePlan({
    required this.source,
    required this.plan,
    required this.scan,
    Iterable<DedupeSkip> unhashed = const [],
  }) : unhashed = List.unmodifiable(unhashed);

  final Source source;

  final Plan plan;

  /// What the scan found, including folders it could not read.
  final ScanSummary scan;

  /// Files that could not be hashed, so their duplicates are unknown.
  final List<DedupeSkip> unhashed;

  SourcePlan withPlan(Plan plan) =>
      SourcePlan(source: source, plan: plan, scan: scan, unhashed: unhashed);

  @override
  bool operator ==(Object other) =>
      other is SourcePlan &&
      other.source == source &&
      other.plan == plan &&
      other.scan == scan &&
      listEquals(other.unhashed, unhashed);

  @override
  int get hashCode => Object.hash(source, plan, scan, Object.hashAll(unhashed));

  @override
  String toString() => 'SourcePlan(${source.id}, $plan)';
}

/// State of the cleanup workflow.
///
/// ```
/// idle → scanning → analyzing → planReady → executing → completed
///   │        │          │            │            ├→ cancelled
///   │        └──────────┴→ idle      │            └→ (failed)
///   │        (cancelled)             └→ idle (plan declined)
///   └→ interrupted (crash found at start) → scanning ("finish") | undoing
/// completed / cancelled / interrupted / partiallyReverted
///   → undoing → reverted / partiallyReverted
/// failed: the pipeline could not produce a plan
/// ```
@immutable
sealed class WorkflowState {
  const WorkflowState();

  /// Whether a command is running; only `cancel` may be called then.
  bool get isBusy => false;
}

/// Nothing going on.
final class Idle extends WorkflowState {
  const Idle();

  @override
  bool operator ==(Object other) => other is Idle;

  @override
  int get hashCode => (Idle).hashCode;

  @override
  String toString() => 'Idle';
}

/// At start-up, sessions a crash interrupted were recovered. The user can
/// finish the job (a new cleanup) or undo them.
final class Interrupted extends WorkflowState {
  Interrupted(
    Iterable<RecoveryResult> recovered, {
    Iterable<SessionId> unavailable = const [],
  }) : recovered = List.unmodifiable(recovered),
       unavailable = List.unmodifiable(unavailable);

  final List<RecoveryResult> recovered;

  /// Interrupted sessions whose source is not available now; they stay
  /// running until it is.
  final List<SessionId> unavailable;

  @override
  bool operator ==(Object other) =>
      other is Interrupted &&
      listEquals(other.recovered, recovered) &&
      listEquals(other.unavailable, unavailable);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(recovered), Object.hashAll(unavailable));

  @override
  String toString() =>
      'Interrupted(${recovered.length} recovered, '
      '${unavailable.length} unavailable)';
}

/// Scanning source [sourceIndex] (from 0) of [sourceCount].
final class Scanning extends WorkflowState {
  const Scanning({
    required this.sourceId,
    required this.sourceIndex,
    required this.sourceCount,
    required this.filesProcessed,
  });

  final SourceId sourceId;
  final int sourceIndex;
  final int sourceCount;
  final int filesProcessed;

  @override
  bool get isBusy => true;

  @override
  bool operator ==(Object other) =>
      other is Scanning &&
      other.sourceId == sourceId &&
      other.sourceIndex == sourceIndex &&
      other.sourceCount == sourceCount &&
      other.filesProcessed == filesProcessed;

  @override
  int get hashCode =>
      Object.hash(sourceId, sourceIndex, sourceCount, filesProcessed);

  @override
  String toString() =>
      'Scanning($sourceId ${sourceIndex + 1}/$sourceCount, '
      '$filesProcessed files)';
}

/// Looking for duplicates and planning source [sourceIndex] of
/// [sourceCount].
final class Analyzing extends WorkflowState {
  const Analyzing({
    required this.sourceId,
    required this.sourceIndex,
    required this.sourceCount,
    required this.sizesDone,
    required this.sizesTotal,
  });

  final SourceId sourceId;
  final int sourceIndex;
  final int sourceCount;

  /// Duplicate detection progress (size buckets).
  final int sizesDone;
  final int sizesTotal;

  @override
  bool get isBusy => true;

  @override
  bool operator ==(Object other) =>
      other is Analyzing &&
      other.sourceId == sourceId &&
      other.sourceIndex == sourceIndex &&
      other.sourceCount == sourceCount &&
      other.sizesDone == sizesDone &&
      other.sizesTotal == sizesTotal;

  @override
  int get hashCode =>
      Object.hash(sourceId, sourceIndex, sourceCount, sizesDone, sizesTotal);

  @override
  String toString() =>
      'Analyzing($sourceId ${sourceIndex + 1}/$sourceCount, '
      '$sizesDone/$sizesTotal)';
}

/// The plans are ready for review and approval.
final class PlanReady extends WorkflowState {
  PlanReady(
    Iterable<SourcePlan> plans, {
    Iterable<SourceId> unavailable = const [],
  }) : plans = List.unmodifiable(plans),
       unavailable = List.unmodifiable(unavailable);

  final List<SourcePlan> plans;

  /// Enabled sources that could not be opened and were not scanned.
  final List<SourceId> unavailable;

  /// Whether there is nothing to do anywhere.
  bool get isEmpty => plans.every((p) => p.plan.isEmpty);

  /// Totals over the approved operations of all sources.
  PlanSummary get approvedSummary {
    var files = 0;
    var bytes = 0;
    for (final p in plans) {
      final summary = p.plan.approvedSummary;
      files += summary.fileCount;
      bytes += summary.reclaimableBytes;
    }
    return PlanSummary(fileCount: files, reclaimableBytes: bytes);
  }

  @override
  bool operator ==(Object other) =>
      other is PlanReady &&
      listEquals(other.plans, plans) &&
      listEquals(other.unavailable, unavailable);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(plans), Object.hashAll(unavailable));

  @override
  String toString() => 'PlanReady(${plans.length} sources)';
}

/// Executing the plan of source [sourceIndex] of [sourceCount].
final class Executing extends WorkflowState {
  const Executing({
    required this.sourceId,
    required this.sourceIndex,
    required this.sourceCount,
    this.progress,
  });

  final SourceId sourceId;
  final int sourceIndex;
  final int sourceCount;

  /// Progress within the current source; `null` before its first operation.
  final ExecutionProgress? progress;

  @override
  bool get isBusy => true;

  @override
  bool operator ==(Object other) =>
      other is Executing &&
      other.sourceId == sourceId &&
      other.sourceIndex == sourceIndex &&
      other.sourceCount == sourceCount &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(sourceId, sourceIndex, sourceCount, progress);

  @override
  String toString() =>
      'Executing($sourceId ${sourceIndex + 1}/$sourceCount, $progress)';
}

/// Undoing session [sessionIndex] of [sessionCount].
final class Undoing extends WorkflowState {
  const Undoing({
    required this.sessionId,
    required this.sessionIndex,
    required this.sessionCount,
    required this.operationsProcessed,
  });

  final SessionId sessionId;
  final int sessionIndex;
  final int sessionCount;

  /// Operations undone (or skipped) so far in this session.
  final int operationsProcessed;

  @override
  bool get isBusy => true;

  @override
  bool operator ==(Object other) =>
      other is Undoing &&
      other.sessionId == sessionId &&
      other.sessionIndex == sessionIndex &&
      other.sessionCount == sessionCount &&
      other.operationsProcessed == operationsProcessed;

  @override
  int get hashCode =>
      Object.hash(sessionId, sessionIndex, sessionCount, operationsProcessed);

  @override
  String toString() =>
      'Undoing($sessionId ${sessionIndex + 1}/$sessionCount, '
      '$operationsProcessed)';
}

/// A state that ends a run and lists its sessions.
sealed class Finished extends WorkflowState {
  Finished(Iterable<CleanupSession> sessions)
    : sessions = List.unmodifiable(sessions);

  final List<CleanupSession> sessions;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is Finished &&
      listEquals(other.sessions, sessions);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(sessions));

  @override
  String toString() => '$runtimeType(${sessions.length} sessions)';
}

/// Every plan was executed (individual failures are in the stats).
final class Completed extends Finished {
  Completed(super.sessions);
}

/// The user stopped the execution; what was done can be undone.
final class Cancelled extends Finished {
  Cancelled(super.sessions);
}

/// Every session was undone.
final class Reverted extends Finished {
  Reverted(super.sessions);
}

/// Some operations could not be undone (see the journal) or the undo was
/// stopped.
final class PartiallyReverted extends Finished {
  PartiallyReverted(super.sessions);
}

/// The pipeline could not produce a plan.
final class Failed extends WorkflowState {
  const Failed(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) => other is Failed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'Failed($reason)';
}
