import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemoryOperationJournal implements OperationJournal {
  final Map<OperationId, Operation> _operations = {};

  /// Every successful append and update, in order, for tests that check
  /// when something was journaled.
  final List<Operation> writes = [];

  @override
  Future<void> append(Operation operation) async {
    RepositoryRules.checkAppend(operation);
    if (_operations.containsKey(operation.id)) {
      throw StateError('Journal: ${operation.id} already exists');
    }
    if (_operations.values.any(
      (o) => o.sessionId == operation.sessionId && o.seq == operation.seq,
    )) {
      throw StateError(
        'Journal: seq ${operation.seq} is taken in ${operation.sessionId}',
      );
    }
    _operations[operation.id] = operation;
    writes.add(operation);
  }

  @override
  Future<void> update(Operation operation) async {
    final stored = _operations[operation.id];
    if (stored == null) {
      throw StateError('Journal: ${operation.id} does not exist');
    }
    RepositoryRules.checkUpdate(stored, operation);
    _operations[operation.id] = operation;
    writes.add(operation);
  }

  @override
  Future<Operation?> byId(OperationId id) async => _operations[id];

  @override
  Future<List<Operation>> bySession(
    SessionId sessionId, {
    String? groupKey,
    bool reverse = false,
  }) async {
    final result =
        _operations.values
            .where(
              (o) =>
                  o.sessionId == sessionId &&
                  (groupKey == null || o.groupKey == groupKey),
            )
            .toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    return reverse ? result.reversed.toList() : result;
  }

  @override
  Future<List<Operation>> doneQuarantinesBefore(DateTime cutoff) async =>
      _operations.values
          .where(
            (o) =>
                o.type == OperationType.quarantine &&
                o.status == OperationStatus.done &&
                o.executedAt!.isBefore(cutoff),
          )
          .toList()
        ..sort((a, b) {
          final byTime = a.executedAt!.compareTo(b.executedAt!);
          return byTime != 0 ? byTime : a.id.value.compareTo(b.id.value);
        });
}
