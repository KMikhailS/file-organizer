import 'package:file_organizer/core/classify/classify.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/planner/planning.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/layout_fixtures.dart';
import '../../support/pipeline_harness.dart';
import '../../support/random_tree.dart';
import '../../support/scenarios.dart';

/// Invariants 1, 5, 6, 7 and 8 on the scenarios and on random trees.
void main() {
  final cases = <String, InMemoryFileSource Function()>{
    'typical Download folder': () =>
        InMemoryFileSource()..withTypicalDownloadFolder(),
    'phone with duplicate photos': phoneStorage,
    'organized document archive': () =>
        InMemoryFileSource()..withOrganizedDocumentArchive(),
    'everything together': () => phoneStorage()
      ..withTypicalDownloadFolder(root: 'Desktop')
      ..withOrganizedDocumentArchive(),
    for (var seed = 0; seed < 40; seed++)
      'random tree $seed': () => randomTree(seed),
    for (var seed = 100; seed < 120; seed++)
      'random case-insensitive tree $seed': () =>
          randomTree(seed, caseSensitive: false),
  };

  for (final MapEntry(key: name, value: build) in cases.entries) {
    group(name, () {
      late InMemoryFileSource fs;
      late PipelineHarness harness;
      late Plan plan;

      setUp(() async {
        fs = build();
        harness = PipelineHarness(fs);
        plan = await harness.readyPlan();
      });

      test('1: nothing is overwritten', () async {
        final targets = <String>{};
        for (final op in plan.operations) {
          if (op.toPath case final to?) {
            expect(
              await fs.exists(to),
              const FileSuccess(false),
              reason: '$to exists',
            );
            expect(
              targets.add(to.value.toLowerCase()),
              isTrue,
              reason: '$to is targeted twice',
            );
          }
        }
        // The whole plan runs without a single targetExists.
        await applyPlan(fs, plan);
      });

      test('5: operations stay in the source', () {
        expect(
          plan.operations.map((o) => o.sourceId).toSet(),
          plan.isEmpty ? isEmpty : {fs.sourceId},
        );
      });

      test('6: excluded, organized and target files stay intact', () async {
        final before = fs.snapshot();
        final touched = {
          for (final op in plan.operations)
            if (op.fromPath case final from?) from.value,
        };
        await applyPlan(fs, plan);
        final after = fs.snapshot();

        for (final MapEntry(key: path, value: file) in before.files.entries) {
          final zone = harness.zones.zoneOfFile(LogicalPath(path));
          if (zone != Zone.chaos) {
            expect(touched, isNot(contains(path)), reason: '$path ($zone)');
            expect(after.files[path], file, reason: '$path ($zone) changed');
          } else if (!touched.contains(path)) {
            expect(after.files[path], file, reason: '$path changed');
          }
        }
      });

      test('7: planning again after the cleanup gives an empty plan', () async {
        await applyPlan(fs, plan);
        final again = await harness.readyPlan();
        expect(describe(again), isEmpty);
        expect(again.isEmpty, isTrue);
      });

      test('8: the same input gives the same plan', () async {
        final other = await PipelineHarness(build()).readyPlan();
        expect(other, plan);

        // Input order does not matter either.
        final files = await harness.index.bySource(fs.sourceId);
        final reversed =
            await Planner(
              classifier: RuleClassifier(),
              template: russianTemplate(),
            ).plan(
              source: fs,
              files: files.reversed,
              zones: harness.zones,
              duplicates: plan.duplicateGroups.reversed,
            );
        expect(reversed, PlanReady(plan));
      });
    });
  }
}
