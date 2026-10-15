import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemoryOperationJournal implements OperationJournal {
  final Map<OperationId, Operation> _operations = {};

  /// Every successful append and update, in order, for tests that check
  /// when something was journaled.
  final List<Operation> writes = [];

  @override
  Future<void> append(Operation operation) => appendAll([operation]);

  @override
  Future<void> update(Operation operation) => updateAll([operation]);

  @override
  Future<void> appendAll(List<Operation> operations) async {
    // Every rule is checked before anything is stored: all or none.
    final ids = <OperationId>{};
    final seqs = <(SessionId, int)>{};
    for (final operation in operations) {
      RepositoryRules.checkAppend(operation);
      if (_operations.containsKey(operation.id) || !ids.add(operation.id)) {
        throw StateError('Journal: ${operation.id} already exists');
      }
      final seq = (operation.sessionId, operation.seq);
      if (_operations.values.any(
            (o) => o.sessionId == operation.sessionId && o.seq == operation.seq,
          ) ||
          !seqs.add(seq)) {
        throw StateError(
          'Journal: seq ${operation.seq} is taken in ${operation.sessionId}',
        );
      }
    }
    for (final operation in operations) {
      _operations[operation.id] = operation;
      writes.add(operation);
    }
  }

  @override
  Future<void> updateAll(List<Operation> operations) async {
    final ids = <OperationId>{};
    for (final operation in operations) {
      final stored = _operations[operation.id];
      if (stored == null) {
        throw StateError('Journal: ${operation.id} does not exist');
      }
      if (!ids.add(operation.id)) {
        throw StateError('Journal: ${operation.id} is updated twice at once');
      }
      RepositoryRules.checkUpdate(stored, operation);
    }
    for (final operation in operations) {
      _operations[operation.id] = operation;
      writes.add(operation);
    }
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
