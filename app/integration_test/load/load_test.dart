// The load test (docs/stage2_android.md, section 10 and 5.25): the whole
// pipeline on FILES files in the test root of a device. Run it with
// run_android.sh, never on its own: the script writes the files, grants
// the access and removes everything afterwards.
//
// Measures the scan, the analysis (duplicates) with planning, the
// execution and the undo, and the peak memory of the process; prints them
// as LOAD|<name>=<value> lines.
import 'dart:io';

import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String root = '/storage/emulated/0/FileOrganizerTest';

void say(String name, Object value) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('LOAD|$name=$value');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('the pipeline on many files', () async {
    final container = ProviderContainer(
      overrides: [
        appServicesProvider.overrideWithValue(
          AppServices.android(testRoot: root),
        ),
        ...localizationOverrides(),
      ],
    );
    addTearDown(container.dispose);
    final app = container.read(appControllerProvider.notifier);
    await app.start();
    expect(container.read(appControllerProvider), const FolderNamesNeeded());
    await app.confirmFolderNames(container.read(proposedFolderNamesProvider));
    expect(container.read(appControllerProvider), isA<AppReady>());

    final workflow = container.read(workflowProvider);
    final firstSeen = <Type, DateTime>{};
    final states = workflow.states.listen(
      (state) => firstSeen.putIfAbsent(state.runtimeType, DateTime.now),
    );
    addTearDown(states.cancel);
    final planning = Stopwatch()..start();
    await workflow.start();
    planning.stop();
    final planned = DateTime.now();
    // The states reach the listener asynchronously: the end of the
    // analysis is when start() returned.
    while (!firstSeen.containsKey(Analyzing)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final ready = workflow.state as PlanReady;
    final plan = ready.plans.single.plan;
    say('plan_ms', planning.elapsedMilliseconds);
    say(
      'scan_ms',
      firstSeen[Analyzing]!.difference(firstSeen[Scanning]!).inMilliseconds,
    );
    say(
      'analyze_and_plan_ms',
      planned.difference(firstSeen[Analyzing]!).inMilliseconds,
    );
    say('files_in_plan', plan.summary.fileCount);
    say('duplicate_groups', plan.duplicateGroups.length);
    say('unresolved', plan.unresolved.length);
    say('rss_after_plan_mb', ProcessInfo.currentRss ~/ (1 << 20));

    final executing = Stopwatch()..start();
    await workflow.execute();
    executing.stop();
    expect(workflow.state, isA<Completed>());
    final stats = (workflow.state as Completed).sessions.single.stats;
    say('execute_ms', executing.elapsedMilliseconds);
    say('done', stats.done);
    say('failed', stats.failed + stats.skipped);

    final undoing = Stopwatch()..start();
    await workflow.undo();
    undoing.stop();
    say('undo_ms', undoing.elapsedMilliseconds);
    say('reverted_state', workflow.state.runtimeType);
    say('peak_rss_mb', ProcessInfo.maxRss ~/ (1 << 20));
    expect(workflow.state, isA<Reverted>());
  }, timeout: const Timeout(Duration(minutes: 90)));
}
