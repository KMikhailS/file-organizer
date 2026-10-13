// A cleanup killed while it moves files, on an emulator
// (docs/stage2_android.md, 5.21). Run it with run_android.sh, never on its
// own: the script refuses any device but an emulator, puts the test files
// into Download/ and runs this test twice on the same app data.
//   PHASE=apply    onboarding, plan, "Apply"; once the moves are under way
//                  it prints INTERRUPTED|EXECUTING and the script kills the
//                  app with `am force-stop`.
//   PHASE=recover  the app starts again: the interrupted cleanup is shown,
//                  "Undo it" brings every file back.
import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/app.dart';
import 'package:file_organizer/ui/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String phase = String.fromEnvironment('PHASE');

void say(String what) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('INTERRUPTED|$what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a cleanup killed in the middle, phase $phase', (tester) async {
    expect(phase, anyOf('apply', 'recover'), reason: 'pass PHASE');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(AppServices.android()),
          ...localizationOverrides(),
        ],
        child: const FileOrganizerApp(),
      ),
    );

    if (phase == 'apply') {
      await _tap(tester, 'Next');
      await _tap(tester, 'Confirm');
      await _tap(tester, 'Tidy up');
      await _until(
        tester,
        find.text('Apply'),
        timeout: const Duration(minutes: 3),
      );
      await _tap(tester, 'Apply');
      // Some moves are done, most are not.
      await _until(tester, find.textContaining(RegExp(r'^[1-9]\d+ of ')));
      say('EXECUTING');
      // The script kills the app now; this never ends on its own.
      await _until(
        tester,
        find.text('never shown'),
        timeout: const Duration(minutes: 2),
      );
      return;
    }

    await _until(
      tester,
      find.text('The last cleanup was interrupted'),
      timeout: const Duration(minutes: 2),
    );
    expect(find.textContaining('Needs attention'), findsNothing);
    say('FOUND');
    await _tap(tester, 'Undo it');
    final yes = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Bring back'),
    );
    await _until(tester, yes);
    await tester.tap(yes);
    await _until(
      tester,
      find.text('Close'),
      timeout: const Duration(minutes: 5),
    );
    expect(find.text('Cleanup undone'), findsOneWidget);
    expect(find.text('What did not work'), findsNothing);
    say('UNDONE');
    await _tap(tester, 'Close');
    await _until(tester, find.text('Tidy up'));
  }, timeout: const Timeout(Duration(minutes: 15)));
}

Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 90),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('not on screen after $timeout: $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await _until(tester, target);
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 300));
}
