import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  const id = SessionId('s1');
  final end = testTime.add(const Duration(minutes: 5));

  CleanupSession planned() => CleanupSession(
    id: id,
    startedAt: testTime,
    status: SessionStatus.planned,
    stats: SessionStats.empty,
  );

  /// A session brought into [status] through allowed transitions.
  CleanupSession inStatus(SessionStatus status) {
    final running = planned().transitionTo(SessionStatus.running);
    return switch (status) {
      SessionStatus.planned => planned(),
      SessionStatus.running => running,
      SessionStatus.completed ||
      SessionStatus.failed ||
      SessionStatus.cancelled => running.transitionTo(status, finishedAt: end),
      SessionStatus.reverted || SessionStatus.partiallyReverted =>
        running
            .transitionTo(SessionStatus.completed, finishedAt: end)
            .transitionTo(status),
    };
  }

  group('SessionStatus', () {
    test('canTransitionTo matches the documented table', () {
      const finishedOrPartial = {
        SessionStatus.reverted,
        SessionStatus.partiallyReverted,
      };
      const allowed = {
        SessionStatus.planned: {SessionStatus.running, SessionStatus.cancelled},
        SessionStatus.running: {
          SessionStatus.completed,
          SessionStatus.failed,
          SessionStatus.cancelled,
        },
        SessionStatus.completed: finishedOrPartial,
        SessionStatus.failed: finishedOrPartial,
        SessionStatus.cancelled: finishedOrPartial,
        SessionStatus.partiallyReverted: finishedOrPartial,
        SessionStatus.reverted: <SessionStatus>{},
      };
      for (final from in SessionStatus.values) {
        for (final to in SessionStatus.values) {
          expect(
            from.canTransitionTo(to),
            allowed[from]!.contains(to),
            reason: '$from -> $to',
          );
        }
      }
    });

    test('isFinished', () {
      expect(SessionStatus.planned.isFinished, isFalse);
      expect(SessionStatus.running.isFinished, isFalse);
      for (final status in SessionStatus.values.skip(2)) {
        expect(status.isFinished, isTrue, reason: '$status');
      }
    });
  });

  group('transitionTo', () {
    test('a full cleanup and undo', () {
      final running = planned().transitionTo(SessionStatus.running);
      expect(running.finishedAt, isNull);

      final completed = running.transitionTo(
        SessionStatus.completed,
        finishedAt: end,
      );
      expect(completed.status, SessionStatus.completed);
      expect(completed.finishedAt, end);

      final partial = completed.transitionTo(SessionStatus.partiallyReverted);
      final reverted = partial.transitionTo(SessionStatus.reverted);
      expect(reverted.status, SessionStatus.reverted);
      expect(reverted.finishedAt, end, reason: 'finish time is kept');
      expect(reverted.startedAt, testTime);
    });

    test('follows canTransitionTo for every status pair', () {
      for (final from in SessionStatus.values) {
        for (final to in SessionStatus.values) {
          final session = inStatus(from);
          final finishes = !from.isFinished && to.isFinished;
          CleanupSession go() =>
              session.transitionTo(to, finishedAt: finishes ? end : null);
          if (from.canTransitionTo(to)) {
            expect(go().status, to, reason: '$from -> $to');
          } else {
            expect(go, throwsStateError, reason: '$from -> $to');
          }
        }
      }
    });

    test('requires finishedAt when execution finishes', () {
      final running = inStatus(SessionStatus.running);
      expect(
        () => running.transitionTo(SessionStatus.completed),
        throwsArgumentError,
      );
      expect(
        () => planned().transitionTo(SessionStatus.cancelled),
        throwsArgumentError,
      );
    });

    test('rejects finishedAt otherwise', () {
      expect(
        () => planned().transitionTo(SessionStatus.running, finishedAt: end),
        throwsArgumentError,
      );
      expect(
        () =>
            inStatus(SessionStatus.completed)
                .transitionTo(SessionStatus.reverted, finishedAt: end),
        throwsArgumentError,
      );
    });
  });

  group('constructor', () {
    test('rejects finishedAt for unfinished sessions', () {
      for (final status in [SessionStatus.planned, SessionStatus.running]) {
        expect(
          () => CleanupSession(
            id: id,
            startedAt: testTime,
            status: status,
            stats: SessionStats.empty,
            finishedAt: end,
          ),
          throwsArgumentError,
        );
      }
    });

    test('requires finishedAt for finished sessions', () {
      expect(
        () => CleanupSession(
          id: id,
          startedAt: testTime,
          status: SessionStatus.completed,
          stats: SessionStats.empty,
        ),
        throwsArgumentError,
      );
    });

    test('rejects finishedAt before startedAt', () {
      expect(
        () => CleanupSession(
          id: id,
          startedAt: end,
          status: SessionStatus.completed,
          stats: SessionStats.empty,
          finishedAt: testTime,
        ),
        throwsArgumentError,
      );
    });

    test('stores dates in UTC', () {
      final session = CleanupSession(
        id: id,
        startedAt: testTime.toLocal(),
        status: SessionStatus.completed,
        stats: SessionStats.empty,
        finishedAt: end.toLocal(),
      );
      expect(session.startedAt.isUtc, isTrue);
      expect(session.finishedAt!.isUtc, isTrue);
      expect(session, inStatus(SessionStatus.completed));
    });
  });

  test('withStats replaces only the stats', () {
    final stats = SessionStats.of([
      Operation.pending(
        id: const OperationId('o'),
        sessionId: id,
        seq: 0,
        planned: plannedMkdir('Documents'),
      ),
    ]);
    final updated = planned().withStats(stats);
    expect(updated.stats, stats);
    expect(updated.withStats(SessionStats.empty), planned());
  });

  test('value equality covers every field', () {
    CleanupSession session({
      SessionId sessionId = id,
      DateTime? startedAt,
      DateTime? finishedAt,
      SessionStatus status = SessionStatus.completed,
      SessionStats? stats,
    }) => CleanupSession(
      id: sessionId,
      startedAt: startedAt ?? testTime,
      status: status,
      stats: stats ?? SessionStats.empty,
      finishedAt: finishedAt ?? end,
    );

    expectValueEquality(session, {
      'id': session(sessionId: const SessionId('s2')),
      'startedAt': session(startedAt: testTime.add(const Duration(seconds: 1))),
      'finishedAt': session(finishedAt: end.add(const Duration(seconds: 1))),
      'status': session(status: SessionStatus.failed),
      'stats': session(
        stats: SessionStats(
          total: 1,
          done: 1,
          failed: 0,
          skipped: 0,
          reverted: 0,
          revertSkipped: 0,
          removedBytes: 0,
        ),
      ),
    });
  });

  group('SessionStats', () {
    test('counts operations by status and removed bytes', () {
      const s = SessionId('s');
      var seq = 0;
      Operation pending(PlannedOperation planned) => Operation.pending(
        id: OperationId('o$seq'),
        sessionId: s,
        seq: seq++,
        planned: planned,
      );
      final at = testTime;

      final operations = [
        pending(plannedMkdir('Documents')),
        pending(plannedMkdir('Photos')).markDone(at: at),
        pending(plannedMove('a.pdf', 'Documents/a.pdf')).markDone(at: at),
        pending(plannedMove('b.pdf', 'Documents/b.pdf')).markFailed(
          at: at,
          error: const FileSystemError(FileErrorKind.locked),
        ),
        pending(plannedMove('c.pdf', 'Documents/c.pdf'))
            .markSkipped(at: at, error: const FileChanged()),
        // Still out of the way: counted in removedBytes.
        pending(plannedQuarantine('d (1).pdf', size: 100))
            .markDone(at: at, quarantineRef: QuarantineRef('q1')),
        pending(plannedQuarantine('e (1).pdf', size: 20))
            .markDone(at: at, quarantineRef: QuarantineRef('q2'))
            .markRevertSkipped(error: const QuarantinePurged()),
        // Restored: not counted.
        pending(plannedQuarantine('f (1).pdf', size: 3))
            .markDone(at: at, quarantineRef: QuarantineRef('q3'))
            .markReverted(at: at),
      ];

      final stats = SessionStats.of(operations);
      expect(
        stats,
        SessionStats(
          total: 8,
          done: 3,
          failed: 1,
          skipped: 1,
          reverted: 1,
          revertSkipped: 1,
          removedBytes: 120,
        ),
      );
      expect(stats.pending, 1);
      expect(SessionStats.of(const []), SessionStats.empty);
    });

    test('rejects negative counts', () {
      expect(
        () => SessionStats(
          total: 1,
          done: -1,
          failed: 0,
          skipped: 0,
          reverted: 0,
          revertSkipped: 0,
          removedBytes: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects counts above total', () {
      expect(
        () => SessionStats(
          total: 1,
          done: 1,
          failed: 1,
          skipped: 0,
          reverted: 0,
          revertSkipped: 0,
          removedBytes: 0,
        ),
        throwsArgumentError,
      );
    });

    test('value equality covers every field', () {
      SessionStats stats({
        int total = 10,
        int done = 1,
        int failed = 1,
        int skipped = 1,
        int reverted = 1,
        int revertSkipped = 1,
        int removedBytes = 1,
      }) => SessionStats(
        total: total,
        done: done,
        failed: failed,
        skipped: skipped,
        reverted: reverted,
        revertSkipped: revertSkipped,
        removedBytes: removedBytes,
      );

      expectValueEquality(stats, {
        'total': stats(total: 11),
        'done': stats(done: 2),
        'failed': stats(failed: 2),
        'skipped': stats(skipped: 2),
        'reverted': stats(reverted: 2),
        'revertSkipped': stats(revertSkipped: 2),
        'removedBytes': stats(removedBytes: 2),
      });
    });
  });
}
