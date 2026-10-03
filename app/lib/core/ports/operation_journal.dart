import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_status.dart';

/// The operation journal: the basis of undo and crash recovery.
///
/// The journal protects its own consistency. Violations are bugs in the
/// caller, not expected outcomes, and throw [StateError].
abstract interface class OperationJournal {
  /// Records a new operation. It must be [OperationStatus.pending], its id
  /// must be new, and its `seq` must be free within its session.
  Future<void> append(Operation operation);

  /// Replaces the stored operation with the same id by [operation].
  ///
  /// Only the status and its fields (`error`, `quarantineRef`,
  /// `executedAt`, `revertedAt`) may change, and only by an allowed
  /// transition (see [OperationStatus]).
  Future<void> update(Operation operation);

  Future<Operation?> byId(OperationId id);

  /// Operations of a session ordered by `seq` (descending if [reverse]),
  /// optionally only those of one plan group.
  Future<List<Operation>> bySession(
    SessionId sessionId, {
    String? groupKey,
    bool reverse = false,
  });

  /// Done quarantine operations of every session executed before [cutoff],
  /// oldest first (then by id).
  Future<List<Operation>> doneQuarantinesBefore(DateTime cutoff);
}
