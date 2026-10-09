// The onboarding of the real app on a device (docs/stage2_android.md,
// 5.17). Run it with run_android.sh, never on its own: the script installs
// the app clean, sets the permissions for the PASS and plays the user on
// the system screens when the test prints ONBOARDING|<action> (see
// integration_test/support/system_ui.sh).
//   PASS=refuse   the access is refused once, then granted; notifications
//                 (Android 13+) are refused and skipped.
//   PASS=granted  the access is granted beforehand (the step is skipped);
//                 notifications (Android 13+) are allowed.
import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/app.dart';
import 'package:file_organizer/ui/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String pass = String.fromEnvironment('PASS');
const int sdkInt = int.fromEnvironment('SDK_INT');

void say(String what) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('ONBOARDING|$what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the onboarding, pass $pass', (tester) async {
    expect(pass, anyOf('refuse', 'granted'), reason: 'pass PASS');
    expect(sdkInt, greaterThan(0), reason: 'pass SDK_INT');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(AppServices.android()),
          ...localizationOverrides(),
        ],
        child: const FileOrganizerApp(),
      ),
    );

    await _until(tester, find.text('Order in your files'));
    await _tap(tester, 'Next');

    if (pass == 'refuse') {
      await _until(tester, find.text('Access to your files'));
      say('ALL_FILES_BACK');
      await _tap(tester, 'Grant access');
      await _until(tester, find.textContaining('not granted yet'));
      expect(find.text('Access to your files'), findsOneWidget);
      say('REFUSAL_SHOWN');

      say('ALL_FILES_GRANT');
      await _tap(tester, 'Grant access');
      await _until(tester, find.text('Access to your files'), gone: true);
    }

    if (sdkInt >= 33) {
      await _until(tester, find.text('Notifications'));
      if (pass == 'refuse') {
        say('NOTIFICATIONS_DENY');
        await _tap(tester, 'Allow notifications');
        await _until(tester, find.textContaining('Notifications are off'));
        await _tap(tester, 'Continue without them');
      } else {
        say('NOTIFICATIONS_ALLOW');
        await _tap(tester, 'Allow notifications');
        // The step goes only when the system reports the permission.
        await _until(tester, find.text('Notifications'), gone: true);
        expect(find.textContaining('Notifications are off'), findsNothing);
      }
    }

    await _until(tester, find.text('Folders for your files'));
    expect(find.text('Access to your files'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey(Category.photos)),
      'Camera',
    );
    await tester.pump();
    await _tap(tester, 'Confirm');
    await _until(tester, find.text('Tidy up'));

    final container = ProviderScope.containerOf(
      tester.element(find.text('Tidy up')),
    );
    expect(
      container.read(layoutFolderNamesProvider)?[Category.photos],
      'Camera',
    );
    // Enabled once the start has opened the storage.
    bool enabled() => tester
        .widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text('Tidy up'),
            matching: find.bySubtype<ButtonStyleButton>(),
          ),
        )
        .enabled;
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!enabled() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(enabled(), isTrue);
    expect(find.text('No access to your files'), findsNothing);
    say('HOME');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// Pumps real frames until [finder] finds something (or nothing, if
/// [gone]): the app waits for the system screens and the database.
Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  bool gone = false,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty != gone) {
    if (DateTime.now().isAfter(deadline)) {
      fail('${gone ? 'still' : 'not'} on screen after $timeout: $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await _until(tester, target);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 200));
}
