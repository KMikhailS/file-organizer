import 'dart:math';

import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fs/in_memory_file_source.dart';
import '../support/pipeline_harness.dart';
import '../support/random_tree.dart';

/// A crash at any point of a cleanup leaves a state that recovery can
/// explain: afterwards the undo restores the original tree, and planning
/// again finishes the job.
void main() {
  /// Runs a cleanup of a random tree and crashes it at a random changing
  /// call. Returns the harness, the original snapshot and the session.
  Future<(PipelineHarness, FsSnapshot, SessionId)?> crashed(int seed) async {
    final random = Random(seed);
    final fs = randomTree(seed, caseSensitive: seed.isOdd);
    final harness = PipelineHarness(fs);
    final plan = await harness.readyPlan();
    final total = plan.approvedOperations.length;
    if (total == 0) {
      return null;
    }
    final original = fs.snapshot();
    fs.crashOn(
      nth: 1 + random.nextInt(total),
      point: CrashPoint.values[random.nextInt(2)],
    );
    final run = harness.executor.start(fs, plan);
    await expectLater(run.result, throwsA(isA<SimulatedCrash>()));
    fs.clearFaults();
    await harness.recovery.recover(run.sessionId, source: fs);
    return (harness, original, run.sessionId);
  }

  group('crash → recovery → undo restores the original tree', () {
    for (var seed = 0; seed < 40; seed++) {
      test('random tree $seed', () async {
        final crash = await crashed(seed);
        if (crash == null) {
          return;
        }
        final (harness, original, sessionId) = crash;
        final undo = await harness.undo(sessionId);
        expect(original.diff(harness.fs.snapshot()), isEmpty);
        expect(undo.session.status, SessionStatus.reverted);
      });
    }
  });

  group('crash → recovery → plan again finishes the job', () {
    for (var seed = 100; seed < 130; seed++) {
      test('random tree $seed', () async {
        final crash = await crashed(seed);
        if (crash == null) {
          return;
        }
        final (harness, _, _) = crash;
        await harness.execute(await harness.readyPlan());
        expect((await harness.readyPlan()).isEmpty, isTrue);
      });
    }
  });
}
