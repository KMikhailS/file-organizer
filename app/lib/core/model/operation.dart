import 'package:file_organizer/core/model/fingerprint.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_reason.dart';
import 'package:file_organizer/core/model/operation_status.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/planned_operation.dart';
import 'package:file_organizer/core/model/quarantine_ref.dart';
import 'package:meta/meta.dart';

/// A journal record: one file operation of a cleanup session.
///
/// Status changes go through the `mark*` methods, which only allow the
/// transitions described in [OperationStatus].
@immutable
final class Operation {
  /// Creates a record with all fields, for example when loading it from
  /// storage.
  ///
  /// Throws [ArgumentError] if the fields are inconsistent:
  /// - the paths and fingerprint do not match [type] (see [OperationType]);
  /// - [seq] is negative;
  /// - [executedAt] is set for a pending operation or missing otherwise;
  /// - [revertedAt] is set unless the status is [OperationStatus.reverted],
  ///   or missing for it;
  /// - [error] is missing for, or set outside of, statuses that carry one;
  /// - [quarantineRef] is set for a non-quarantine or pending operation.
  factory Operation({
    required OperationId id,
    required SessionId sessionId,
    required int seq,
    required OperationType type,
    required SourceId sourceId,
    required LogicalPath? fromPath,
    required LogicalPath? toPath,
    required Fingerprint? fingerprint,
    required OperationReason reason,
    required String groupKey,
    required OperationStatus status,
    QuarantineRef? quarantineRef,
    OperationProblem? error,
    DateTime? executedAt,
    DateTime? revertedAt,
  }) {
    type.checkShape(
      fromPath: fromPath,
      toPath: toPath,
      fingerprint: fingerprint,
    );
    RangeError.checkNotNegative(seq, 'seq');

    Never fail(String message) =>
        throw ArgumentError('Operation $id (${status.name}): $message');

    final pending = status == OperationStatus.pending;
    final reverted = status == OperationStatus.reverted;
    if ((executedAt == null) != pending) {
      fail('executedAt must be set exactly when the operation left pending');
    }
    if ((revertedAt == null) == reverted) {
      fail('revertedAt must be set exactly for reverted operations');
    }
    if ((error != null) != status.hasError) {
      fail('error must be set exactly for failed, skipped and revertSkipped');
    }
    if (quarantineRef != null &&
        (type != OperationType.quarantine || pending)) {
      fail('quarantineRef is only for executed quarantine operations');
    }

    return Operation._(
      id: id,
      sessionId: sessionId,
      seq: seq,
      type: type,
      sourceId: sourceId,
      fromPath: fromPath,
      toPath: toPath,
      fingerprint: fingerprint,
      reason: reason,
      groupKey: groupKey,
      status: status,
      quarantineRef: quarantineRef,
      error: error,
      executedAt: executedAt?.toUtc(),
      revertedAt: revertedAt?.toUtc(),
    );
  }

  /// A new pending record for [planned].
  factory Operation.pending({
    required OperationId id,
    required SessionId sessionId,
    required int seq,
    required PlannedOperation planned,
  }) => Operation(
    id: id,
    sessionId: sessionId,
    seq: seq,
    type: planned.type,
    sourceId: planned.sourceId,
    fromPath: planned.fromPath,
    toPath: planned.toPath,
    fingerprint: planned.fingerprint,
    reason: planned.reason,
    groupKey: planned.groupKey,
    status: OperationStatus.pending,
  );

  const Operation._({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.type,
    required this.sourceId,
    required this.fromPath,
    required this.toPath,
    required this.fingerprint,
    required this.reason,
    required this.groupKey,
    required this.status,
    required this.quarantineRef,
    required this.error,
    required this.executedAt,
    required this.revertedAt,
  });

  final OperationId id;

  final SessionId sessionId;

  /// Order within the session. Undo goes in reverse order of [seq].
  final int seq;

  final OperationType type;

  final SourceId sourceId;

  /// See [OperationType] for which paths each type uses.
  final LogicalPath? fromPath;

  final LogicalPath? toPath;

  /// The file as indexed at planning time; `null` for mkdir.
  final Fingerprint? fingerprint;

  /// Set once a quarantine operation is done.
  final QuarantineRef? quarantineRef;

  /// Why the plan had this operation; the UI turns it into text.
  final OperationReason reason;

  /// Plan group, for the report and partial undo.
  final String groupKey;

  final OperationStatus status;

  /// What went wrong; set for failed, skipped and revertSkipped.
  final OperationProblem? error;

  /// When the operation left [OperationStatus.pending], in UTC.
  final DateTime? executedAt;

  /// When the operation was undone, in UTC.
  final DateTime? revertedAt;

  /// pending → done. [quarantineRef] is only for quarantine operations.
  Operation markDone({required DateTime at, QuarantineRef? quarantineRef}) =>
      _to(OperationStatus.done, executedAt: at, quarantineRef: quarantineRef);

  /// pending → failed.
  Operation markFailed({
    required DateTime at,
    required OperationProblem error,
  }) => _to(OperationStatus.failed, executedAt: at, error: error);

  /// pending → skipped.
  Operation markSkipped({
    required DateTime at,
    required OperationProblem error,
  }) => _to(OperationStatus.skipped, executedAt: at, error: error);

  /// done or revertSkipped → reverted.
  Operation markReverted({required DateTime at}) => _to(
    OperationStatus.reverted,
    executedAt: executedAt,
    quarantineRef: quarantineRef,
    revertedAt: at,
  );

  /// done or revertSkipped → revertSkipped.
  Operation markRevertSkipped({required OperationProblem error}) => _to(
    OperationStatus.revertSkipped,
    executedAt: executedAt,
    quarantineRef: quarantineRef,
    error: error,
  );

  Operation _to(
    OperationStatus next, {
    required DateTime? executedAt,
    QuarantineRef? quarantineRef,
    OperationProblem? error,
    DateTime? revertedAt,
  }) {
    if (!status.canTransitionTo(next)) {
      throw StateError(
        'Operation $id: cannot go from ${status.name} to ${next.name}',
      );
    }
    return Operation(
      id: id,
      sessionId: sessionId,
      seq: seq,
      type: type,
      sourceId: sourceId,
      fromPath: fromPath,
      toPath: toPath,
      fingerprint: fingerprint,
      reason: reason,
      groupKey: groupKey,
      status: next,
      quarantineRef: quarantineRef,
      error: error,
      executedAt: executedAt,
      revertedAt: revertedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Operation &&
      other.id == id &&
      other.sessionId == sessionId &&
      other.seq == seq &&
      other.type == type &&
      other.sourceId == sourceId &&
      other.fromPath == fromPath &&
      other.toPath == toPath &&
      other.fingerprint == fingerprint &&
      other.quarantineRef == quarantineRef &&
      other.reason == reason &&
      other.groupKey == groupKey &&
      other.status == status &&
      other.error == error &&
      other.executedAt == executedAt &&
      other.revertedAt == revertedAt;

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    type,
    sourceId,
    fromPath,
    toPath,
    fingerprint,
    quarantineRef,
    reason,
    groupKey,
    status,
    error,
    executedAt,
    revertedAt,
  );

  @override
  String toString() =>
      'Operation($id #$seq ${type.name} $sourceId: $fromPath -> $toPath, '
      '${status.name}${error == null ? '' : ': $error'})';
}
