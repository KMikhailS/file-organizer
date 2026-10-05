import 'dart:math';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/undo/undo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fs/in_memory_file_source.dart';
import '../support/pipeline_harness.dart';
import '../support/random_tree.dart';

/// Invariant 4: executing a plan and then undoing it completely gives back
/// the original file tree, whatever the tree, failures or cancellation.
void main() {
  Future<void> expectRoundTrip(
    InMemoryFileSource fs, {
    Random? chaos,
    bool groupByGroup = false,
  }) async {
    final harness = PipelineHarness(fs);
    final plan = await harness.readyPlan();
    final original = fs.snapshot();

    // Optionally break the cleanup: a failing call and a cancel midway.
    final total = plan.approvedOperations.length;
    var cancelAt = -1;
    if (chaos != null && total > 0) {
      fs.failOn(
        FileErrorKind.values[chaos.nextInt(FileErrorKind.values.length)],
        methods: FsMethod.mutating,
        nth: 1 + chaos.nextInt(total),
      );
      if (chaos.nextBool()) {
        cancelAt = 1 + chaos.nextInt(total);
      }
    }
    final run = harness.executor.start(fs, plan);
    run.progress.listen((p) {
      if (p.processed == cancelAt) {
        run.cancel();
      }
    });
    final session = await run.result;
    fs.clearFaults();

    if (groupByGroup) {
      final groups = {for (final op in plan.operations) op.groupKey}.toList()
        ..shuffle(chaos ?? Random(0));
      for (final group in groups) {
        await harness.undo(session.id, scope: OneGroup(group));
      }
    }
    final result = await harness.undo(session.id);

    expect(original.diff(fs.snapshot()), isEmpty);
    expect(result.session.status, SessionStatus.reverted);
  }

  group('execute + full undo restores the original tree', () {
    for (var seed = 0; seed < 40; seed++) {
      test('random tree $seed', () => expectRoundTrip(randomTree(seed)));
    }
    for (var seed = 100; seed < 120; seed++) {
      test('random case-insensitive tree $seed', () {
        return expectRoundTrip(randomTree(seed, caseSensitive: false));
      });
    }
  });

  group('even after failures and cancellation', () {
    for (var seed = 200; seed < 240; seed++) {
      test('random tree $seed', () {
        return expectRoundTrip(randomTree(seed), chaos: Random(seed));
      });
    }
  });

  group('even when undone group by group first', () {
    for (var seed = 300; seed < 320; seed++) {
      test('random tree $seed', () {
        return expectRoundTrip(
          randomTree(seed, caseSensitive: seed.isEven),
          chaos: Random(seed),
          groupByGroup: true,
        );
      });
    }
  });
}
