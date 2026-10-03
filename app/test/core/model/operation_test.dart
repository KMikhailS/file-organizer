import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  const id = OperationId('op1');
  const session = SessionId('s1');
  final at = testTime.add(const Duration(minutes: 1));
  final later = testTime.add(const Duration(days: 1));

  Operation pendingOf(PlannedOperation planned, {int seq = 0}) =>
      Operation.pending(id: id, sessionId: session, seq: seq, planned: planned);

  final move = pendingOf(plannedMove('Download/a.pdf', 'Documents/a.pdf'));
  final quarantine = pendingOf(plannedQuarantine('Download/a (1).pdf'));
  final ref = QuarantineRef('quarantine/s1/1');

  /// [move] brought into [status] through allowed transitions.
  Operation moveIn(OperationStatus status) => switch (status) {
    OperationStatus.pending => move,
    OperationStatus.done => move.markDone(at: at),
    OperationStatus.failed => move.markFailed(at: at, error: 'locked'),
    OperationStatus.skipped => move.markSkipped(at: at, reason: 'changed'),
    OperationStatus.reverted => move.markDone(at: at).markReverted(at: later),
    OperationStatus.revertSkipped =>
      move.markDone(at: at).markRevertSkipped(reason: 'missing'),
  };

  group('pending', () {
    test('copies the planned operation', () {
      final planned = plannedMove('a.pdf', 'Documents/a.pdf', groupKey: 'docs');
      final op = pendingOf(planned, seq: 7);
      expect(op.id, id);
      expect(op.sessionId, session);
      expect(op.seq, 7);
      expect(op.type, planned.type);
      expect(op.sourceId, planned.sourceId);
      expect(op.fromPath, planned.fromPath);
      expect(op.toPath, planned.toPath);
      expect(op.fingerprint, planned.fingerprint);
      expect(op.reason, planned.reason);
      expect(op.groupKey, 'docs');
      expect(op.status, OperationStatus.pending);
      expect(op.executedAt, isNull);
      expect(op.revertedAt, isNull);
      expect(op.error, isNull);
      expect(op.quarantineRef, isNull);
    });

    test('works for every operation type', () {
      expect(pendingOf(plannedMkdir('Documents')).type, OperationType.mkdir);
      expect(quarantine.type, OperationType.quarantine);
    });
  });

  group('transitions', () {
    test('done keeps the quarantine reference', () {
      final done = quarantine.markDone(at: at, quarantineRef: ref);
      expect(done.status, OperationStatus.done);
      expect(done.executedAt, at);
      expect(done.quarantineRef, ref);
    });

    test('failed and skipped carry the error', () {
      final failed = move.markFailed(at: at, error: 'permission denied');
      expect(failed.status, OperationStatus.failed);
      expect(failed.error, 'permission denied');
      expect(failed.executedAt, at);

      final skipped = move.markSkipped(at: at, reason: 'file changed');
      expect(skipped.status, OperationStatus.skipped);
      expect(skipped.error, 'file changed');
    });

    test('reverted keeps execution data and clears the error', () {
      final done = quarantine.markDone(at: at, quarantineRef: ref);
      final reverted = done.markReverted(at: later);
      expect(reverted.status, OperationStatus.reverted);
      expect(reverted.executedAt, at);
      expect(reverted.revertedAt, later);
      expect(reverted.quarantineRef, ref);

      final retried = done
          .markRevertSkipped(reason: 'target occupied')
          .markReverted(at: later);
      expect(retried.status, OperationStatus.reverted);
      expect(retried.error, isNull);
    });

    test('revertSkipped can be retried', () {
      final skipped = moveIn(OperationStatus.revertSkipped);
      final again = skipped.markRevertSkipped(reason: 'still missing');
      expect(again.status, OperationStatus.revertSkipped);
      expect(again.error, 'still missing');
      expect(again.executedAt, at);
    });

    test('mark methods follow canTransitionTo for every status pair', () {
      final marks = <OperationStatus, Operation Function(Operation)>{
        OperationStatus.done: (o) => o.markDone(at: at),
        OperationStatus.failed: (o) => o.markFailed(at: at, error: 'e'),
        OperationStatus.skipped: (o) => o.markSkipped(at: at, reason: 'r'),
        OperationStatus.reverted: (o) => o.markReverted(at: later),
        OperationStatus.revertSkipped: (o) => o.markRevertSkipped(reason: 'r'),
      };
      for (final from in OperationStatus.values) {
        for (final MapEntry(key: to, value: mark) in marks.entries) {
          final op = moveIn(from);
          if (from.canTransitionTo(to)) {
            expect(mark(op).status, to, reason: '$from -> $to');
          } else {
            expect(() => mark(op), throwsStateError, reason: '$from -> $to');
          }
        }
      }
    });

    test('canTransitionTo matches the documented table', () {
      const allowed = {
        OperationStatus.pending: {
          OperationStatus.done,
          OperationStatus.failed,
          OperationStatus.skipped,
        },
        OperationStatus.done: {
          OperationStatus.reverted,
          OperationStatus.revertSkipped,
        },
        OperationStatus.revertSkipped: {
          OperationStatus.reverted,
          OperationStatus.revertSkipped,
        },
        OperationStatus.failed: <OperationStatus>{},
        OperationStatus.skipped: <OperationStatus>{},
        OperationStatus.reverted: <OperationStatus>{},
      };
      for (final from in OperationStatus.values) {
        for (final to in OperationStatus.values) {
          expect(
            from.canTransitionTo(to),
            allowed[from]!.contains(to),
            reason: '$from -> $to',
          );
        }
      }
    });

    test('nothing goes back to pending', () {
      for (final from in OperationStatus.values) {
        expect(from.canTransitionTo(OperationStatus.pending), isFalse);
      }
    });

    test('a quarantine reference is rejected for a move', () {
      expect(
        () => move.markDone(at: at, quarantineRef: ref),
        throwsArgumentError,
      );
    });
  });

  group('constructor rejects inconsistent records', () {
    Operation build({
      OperationType type = OperationType.move,
      LogicalPath? fromPath,
      LogicalPath? toPath,
      Fingerprint? fp,
      int seq = 0,
      OperationStatus status = OperationStatus.done,
      QuarantineRef? quarantineRef,
      String? error,
      DateTime? executedAt,
      DateTime? revertedAt,
    }) => Operation(
      id: id,
      sessionId: session,
      seq: seq,
      type: type,
      sourceId: testSource,
      fromPath: fromPath ?? p('a.pdf'),
      toPath: toPath ?? p('b.pdf'),
      fingerprint: fp ?? fingerprint(),
      reason: 'r',
      groupKey: 'g',
      status: status,
      quarantineRef: quarantineRef,
      error: error,
      executedAt: executedAt,
      revertedAt: revertedAt,
    );

    test('a consistent record is accepted', () {
      expect(build(executedAt: at).status, OperationStatus.done);
    });

    test('a shape that does not match the type', () {
      expect(
        () => build(type: OperationType.quarantine, executedAt: at),
        throwsArgumentError,
      );
    });

    test('a negative seq', () {
      expect(() => build(seq: -1, executedAt: at), throwsArgumentError);
    });

    test('executedAt on a pending operation', () {
      expect(
        () => build(status: OperationStatus.pending, executedAt: at),
        throwsArgumentError,
      );
    });

    test('no executedAt on an executed operation', () {
      expect(build, throwsArgumentError);
    });

    test('revertedAt outside of reverted', () {
      expect(
        () => build(executedAt: at, revertedAt: later),
        throwsArgumentError,
      );
    });

    test('no revertedAt on a reverted operation', () {
      expect(
        () => build(status: OperationStatus.reverted, executedAt: at),
        throwsArgumentError,
      );
    });

    test('an error on a done operation', () {
      expect(() => build(executedAt: at, error: 'e'), throwsArgumentError);
    });

    for (final status in [
      OperationStatus.failed,
      OperationStatus.skipped,
      OperationStatus.revertSkipped,
    ]) {
      test('no error on a ${status.name} operation', () {
        expect(
          () => build(status: status, executedAt: at),
          throwsArgumentError,
        );
      });
    }

    test('a quarantine reference on a move', () {
      expect(
        () => build(executedAt: at, quarantineRef: ref),
        throwsArgumentError,
      );
    });

    test('a quarantine reference on a pending quarantine', () {
      expect(
        () => Operation(
          id: id,
          sessionId: session,
          seq: 0,
          type: OperationType.quarantine,
          sourceId: testSource,
          fromPath: p('a.pdf'),
          toPath: null,
          fingerprint: fingerprint(),
          reason: 'r',
          groupKey: 'g',
          status: OperationStatus.pending,
          quarantineRef: ref,
        ),
        throwsArgumentError,
      );
    });
  });

  test('stores dates in UTC', () {
    final done = move
        .markDone(at: at.toLocal())
        .markReverted(at: later.toLocal());
    expect(done.executedAt!.isUtc, isTrue);
    expect(done.revertedAt!.isUtc, isTrue);
    expect(done, move.markDone(at: at).markReverted(at: later));
  });

  test('value equality covers every field', () {
    Operation op({
      OperationId opId = id,
      SessionId sessionId = session,
      int seq = 0,
      OperationType type = OperationType.quarantine,
      SourceId sourceId = testSource,
      String from = 'a.pdf',
      Fingerprint? fp,
      QuarantineRef? quarantineRef,
      String reason = 'r',
      String groupKey = 'g',
      OperationStatus status = OperationStatus.revertSkipped,
      String error = 'missing',
      DateTime? executedAt,
    }) => Operation(
      id: opId,
      sessionId: sessionId,
      seq: seq,
      type: type,
      sourceId: sourceId,
      fromPath: p(from),
      toPath: type == OperationType.move ? p('b.pdf') : null,
      fingerprint: fp ?? fingerprint(),
      quarantineRef: type == OperationType.quarantine
          ? quarantineRef ?? ref
          : null,
      reason: reason,
      groupKey: groupKey,
      status: status,
      error: status.hasError ? error : null,
      executedAt: executedAt ?? at,
      revertedAt: status == OperationStatus.reverted ? later : null,
    );

    expectValueEquality(op, {
      'id': op(opId: const OperationId('op2')),
      'sessionId': op(sessionId: const SessionId('s2')),
      'seq': op(seq: 1),
      'type and toPath': op(type: OperationType.move),
      'sourceId': op(sourceId: const SourceId('other')),
      'fromPath': op(from: 'c.pdf'),
      'fingerprint': op(fp: fingerprint(size: 1)),
      'quarantineRef': op(quarantineRef: QuarantineRef('other')),
      'reason': op(reason: 'other'),
      'groupKey': op(groupKey: 'other'),
      'status, error and revertedAt': op(status: OperationStatus.reverted),
      'error': op(error: 'other'),
      'executedAt': op(executedAt: later),
    });
  });

  test('toPath and revertedAt take part in equality on their own', () {
    final toB = pendingOf(plannedMove('a.pdf', 'b.pdf'));
    final toC = pendingOf(plannedMove('a.pdf', 'c.pdf'));
    expect(toB, isNot(toC));

    final done = move.markDone(at: at);
    expect(
      done.markReverted(at: later),
      isNot(done.markReverted(at: later.add(const Duration(seconds: 1)))),
    );
  });
}
