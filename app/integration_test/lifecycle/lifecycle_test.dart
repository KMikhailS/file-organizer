// The cleanup survives leaving the app (docs/stage2_android.md, sections
// 5.3 and 5.13). Run it with run_android.sh, never on its own: the script
// prepares large duplicates. While analyzing, this test closes its screen
// (the activity finishes, as with "back") and prints LIFECYCLE|LEFT; the
// script then tries to kill the process, checks the notification, and
// opens the app again.
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void say(String what) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('LIFECYCLE|$what');
}

void main() {
  // A second engine would run this again: the script counts the lines.
  say('main');
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('a cleanup goes on in the background and the app comes back to '
      'it', () async {
    final container = ProviderContainer(
      overrides: [
        appServicesProvider.overrideWithValue(AppServices.android()),
        ...localizationOverrides(),
      ],
    );
    addTearDown(container.dispose);
    final app = container.read(appControllerProvider.notifier);
    await app.start();
    // The first start after a clean install asks for the folder names.
    if (container.read(appControllerProvider) is FolderNamesNeeded) {
      await app.confirmFolderNames(container.read(proposedFolderNamesProvider));
    }
    expect(container.read(appControllerProvider), isA<AppReady>());

    final lifecycle = <AppLifecycleState>[];
    final listener = AppLifecycleListener(onStateChange: lifecycle.add);
    addTearDown(listener.dispose);

    // Workflow states that arrive while the app is not on screen.
    var inBackground = 0;
    final workflow = container.read(workflowProvider);
    final states = workflow.states.listen((_) {
      final now = WidgetsBinding.instance.lifecycleState;
      if (now != null && now != AppLifecycleState.resumed) {
        inBackground++;
      }
    });
    addTearDown(states.cancel);

    final planning = workflow.start();
    await _until(() => workflow.state is Analyzing, const Duration(minutes: 2));
    // Finishes the activity; the engine must outlive it.
    await SystemNavigator.pop();
    say('LEFT');

    await _until(
      () =>
          lifecycle.contains(AppLifecycleState.paused) &&
          lifecycle.last == AppLifecycleState.resumed,
      const Duration(minutes: 3),
    );
    say('BACK inBackground=$inBackground');
    expect(inBackground, greaterThan(0), reason: 'work went on in background');
    expect(
      workflow.state,
      anyOf(isA<Analyzing>(), isA<PlanReady>()),
      reason: 'the same workflow, not a new one',
    );

    await planning;
    expect(workflow.state, isA<PlanReady>());
    say('DONE');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

Future<void> _until(bool Function() condition, Duration timeout) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
