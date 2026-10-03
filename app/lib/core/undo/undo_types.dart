import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:meta/meta.dart';

/// What to undo within a session.
@immutable
sealed class UndoScope {
  const UndoScope();
}

/// Every operation of the session.
final class WholeSession extends UndoScope {
  const WholeSession();

  @override
  bool operator ==(Object other) => other is WholeSession;

  @override
  int get hashCode => (WholeSession).hashCode;
}

/// The operations of one plan group, such as `duplicates`.
final class OneGroup extends UndoScope {
  const OneGroup(this.groupKey);

  final String groupKey;

  @override
  bool operator ==(Object other) =>
      other is OneGroup && other.groupKey == groupKey;

  @override
  int get hashCode => groupKey.hashCode;
}

/// A single operation.
final class OneOperation extends UndoScope {
  const OneOperation(this.operationId);

  final OperationId operationId;

  @override
  bool operator ==(Object other) =>
      other is OneOperation && other.operationId == operationId;

  @override
  int get hashCode => operationId.hashCode;
}

/// What happened to one operation during undo.
@immutable
final class UndoEntry {
  const UndoEntry(this.operation, {this.restoredAs});

  /// The operation as journaled after the attempt: reverted or
  /// revertSkipped (with the reason in `error`).
  final Operation operation;

  /// Where the file went back to when its original place was taken.
  final LogicalPath? restoredAs;

  @override
  bool operator ==(Object other) =>
      other is UndoEntry &&
      other.operation == operation &&
      other.restoredAs == restoredAs;

  @override
  int get hashCode => Object.hash(operation, restoredAs);

  @override
  String toString() =>
      'UndoEntry(${operation.id} ${operation.status.name}'
      '${restoredAs == null ? '' : ' as $restoredAs'})';
}

/// Outcome of an undo.
@immutable
final class UndoResult {
  UndoResult(this.session, Iterable<UndoEntry> entries)
    : entries = List.unmodifiable(entries);

  /// The session after the undo: reverted or partially reverted.
  final CleanupSession session;

  /// One entry per attempted operation, in undo order.
  final List<UndoEntry> entries;

  @override
  bool operator ==(Object other) =>
      other is UndoResult &&
      other.session == session &&
      listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(session, Object.hashAll(entries));

  @override
  String toString() => 'UndoResult(${session.status.name}, $entries)';
}
