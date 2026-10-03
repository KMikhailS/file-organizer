import 'package:file_organizer/core/model/fingerprint.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:meta/meta.dart';

/// One operation of a cleanup plan, not executed yet.
///
/// Use the named constructors; each checks that the fields match the type
/// (see [OperationType]). An operation always stays inside its source.
@immutable
final class PlannedOperation {
  /// Creates the folder [path].
  factory PlannedOperation.mkdir({
    required SourceId sourceId,
    required LogicalPath path,
    required String reason,
    required String groupKey,
    required bool approved,
  }) => PlannedOperation._checked(
    type: OperationType.mkdir,
    sourceId: sourceId,
    fromPath: null,
    toPath: path,
    fingerprint: null,
    reason: reason,
    groupKey: groupKey,
    approved: approved,
  );

  /// Moves the file at [from] to [to].
  factory PlannedOperation.move({
    required SourceId sourceId,
    required LogicalPath from,
    required LogicalPath to,
    required Fingerprint fingerprint,
    required String reason,
    required String groupKey,
    required bool approved,
  }) => PlannedOperation._checked(
    type: OperationType.move,
    sourceId: sourceId,
    fromPath: from,
    toPath: to,
    fingerprint: fingerprint,
    reason: reason,
    groupKey: groupKey,
    approved: approved,
  );

  /// Puts the file at [path] into quarantine.
  factory PlannedOperation.quarantine({
    required SourceId sourceId,
    required LogicalPath path,
    required Fingerprint fingerprint,
    required String reason,
    required String groupKey,
    required bool approved,
  }) => PlannedOperation._checked(
    type: OperationType.quarantine,
    sourceId: sourceId,
    fromPath: path,
    toPath: null,
    fingerprint: fingerprint,
    reason: reason,
    groupKey: groupKey,
    approved: approved,
  );

  /// Adds the file at [path] to the "to delete" album (iOS Photos).
  factory PlannedOperation.addToAlbum({
    required SourceId sourceId,
    required LogicalPath path,
    required Fingerprint fingerprint,
    required String reason,
    required String groupKey,
    required bool approved,
  }) => PlannedOperation._checked(
    type: OperationType.addToAlbum,
    sourceId: sourceId,
    fromPath: path,
    toPath: null,
    fingerprint: fingerprint,
    reason: reason,
    groupKey: groupKey,
    approved: approved,
  );

  factory PlannedOperation._checked({
    required OperationType type,
    required SourceId sourceId,
    required LogicalPath? fromPath,
    required LogicalPath? toPath,
    required Fingerprint? fingerprint,
    required String reason,
    required String groupKey,
    required bool approved,
  }) {
    type.checkShape(
      fromPath: fromPath,
      toPath: toPath,
      fingerprint: fingerprint,
    );
    return PlannedOperation._(
      type: type,
      sourceId: sourceId,
      fromPath: fromPath,
      toPath: toPath,
      fingerprint: fingerprint,
      reason: reason,
      groupKey: groupKey,
      approved: approved,
    );
  }

  const PlannedOperation._({
    required this.type,
    required this.sourceId,
    required this.fromPath,
    required this.toPath,
    required this.fingerprint,
    required this.reason,
    required this.groupKey,
    required this.approved,
  });

  final OperationType type;

  final SourceId sourceId;

  /// The file the operation acts on; `null` for [OperationType.mkdir].
  final LogicalPath? fromPath;

  /// The new location (move) or the folder to create (mkdir); `null`
  /// otherwise.
  final LogicalPath? toPath;

  /// The file as indexed at planning time; `null` for [OperationType.mkdir].
  final Fingerprint? fingerprint;

  /// Human-readable reason, shown in the plan.
  final String reason;

  /// Key of the plan group (for the UI and partial undo).
  final String groupKey;

  /// Whether the user approved the operation.
  final bool approved;

  /// A copy with [approved] changed.
  PlannedOperation withApproved({required bool approved}) => PlannedOperation._(
    type: type,
    sourceId: sourceId,
    fromPath: fromPath,
    toPath: toPath,
    fingerprint: fingerprint,
    reason: reason,
    groupKey: groupKey,
    approved: approved,
  );

  @override
  bool operator ==(Object other) =>
      other is PlannedOperation &&
      other.type == type &&
      other.sourceId == sourceId &&
      other.fromPath == fromPath &&
      other.toPath == toPath &&
      other.fingerprint == fingerprint &&
      other.reason == reason &&
      other.groupKey == groupKey &&
      other.approved == approved;

  @override
  int get hashCode => Object.hash(
    type,
    sourceId,
    fromPath,
    toPath,
    fingerprint,
    reason,
    groupKey,
    approved,
  );

  @override
  String toString() =>
      'PlannedOperation(${type.name} $sourceId: $fromPath -> $toPath, '
      'group: $groupKey, approved: $approved)';
}
