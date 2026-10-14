// The full cycle of the real app on a device (docs/stage2_android.md,
// section 10 and 5.25), on the test root only: the script fills
// FileOrganizerTest/ with "a phone with duplicate photos" and "a typical
// Download folder", and the app takes that folder for the storage.
//
// Onboarding with the permissions → "Tidy up" → plan → "Apply" → while it
// executes, the script presses Home and comes back (the work must go on)
// → the result; the layout on disk is checked → "Undo the cleanup" → the
// script compares the tree with the one before, file by file.
import 'dart:io';

import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/app.dart';
import 'package:file_organizer/ui/texts/localized_app_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String root = '/storage/emulated/0/FileOrganizerTest';
const int sdkInt = int.fromEnvironment('SDK_INT');

void say(String what) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('CYCLE|$what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the full cycle on the test root', (tester) async {
    expect(sdkInt, greaterThan(0), reason: 'pass SDK_INT');
    expect(File('$root/Download/notes.txt').existsSync(), isTrue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(
            AppServices.android(testRoot: root),
          ),
          // English whatever the device language: the test finds texts
          // and folder names in English.
          appTextsFactoryProvider.overrideWithValue(
            LocalizedAppTexts.forLanguages,
          ),
          systemLanguagesProvider.overrideWith(() => SystemLanguages(['en'])),
        ],
        child: const FileOrganizerApp(),
      ),
    );

    // Onboarding with the permissions, granted on the system screens.
    await _tap(tester, 'Next');
    say('ALL_FILES_GRANT');
    await _tap(tester, 'Grant access');
    if (sdkInt >= 33) {
      await _until(tester, find.text('Allow notifications'));
      say('NOTIFICATIONS_ALLOW');
      await _tap(tester, 'Allow notifications');
    }
    await _tap(tester, 'Confirm');

    await _tap(tester, 'Tidy up');
    await _until(
      tester,
      find.text('Cleanup plan'),
      timeout: const Duration(minutes: 5),
    );
    expect(find.textContaining('Duplicates: 3 files'), findsOneWidget);
    say('PLAN');

    // Leave the app while it executes; it must go on in the background.
    final lifecycle = <AppLifecycleState>[];
    final listener = AppLifecycleListener(onStateChange: lifecycle.add);
    addTearDown(listener.dispose);
    await _tap(tester, 'Apply');
    await _until(tester, find.textContaining(RegExp(r'^[1-9]\d* of ')));
    say('LEAVE');
    await _until(
      tester,
      find.text('Cleanup done'),
      timeout: const Duration(minutes: 5),
    );
    await _untilTrue(
      tester,
      () =>
          lifecycle.contains(AppLifecycleState.paused) &&
          lifecycle.last == AppLifecycleState.resumed,
    );
    say('APPLIED');
    // A pause before the undo: the script checks that the service has
    // stopped and let go of its wake lock.
    final checked = DateTime.now().add(const Duration(seconds: 5));
    await _untilTrue(tester, () => DateTime.now().isAfter(checked));

    void at(String path, {bool exists = true}) =>
        expect(File('$root/$path').existsSync(), exists, reason: path);
    at('Documents/invoice_2024.pdf');
    at('Documents/Report.docx');
    at('Documents/notes.txt');
    at('Documents/note_0001.txt');
    at('Music/song.mp3');
    at('Archives/backup.zip');
    at('Installers/app-release.apk');
    at('Photos/2021/photo.jpg');
    at('Screenshots/2024/Screenshot_20240301-120000.png');
    at('Videos/2024/holiday.mp4');
    // Not sure, excluded, or the user's own: they stay.
    at('Download/data.xyz');
    at('Download/README');
    at('Download/project/pubspec.yaml');
    at('DCIM/Camera/IMG_20210506_070809.jpg');
    // Extra copies went to the quarantine.
    at('Download/invoice_2024 (1).pdf', exists: false);
    at('Telegram/Telegram Images/photo_copy.jpg', exists: false);
    at('WhatsApp/Media/WhatsApp Images/IMG-20210507-WA0001.jpg', exists: false);

    await _tap(tester, 'Undo the cleanup');
    final yes = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Bring back'),
    );
    await _until(tester, yes);
    await tester.tap(yes);
    await _until(
      tester,
      find.text('Cleanup undone'),
      timeout: const Duration(minutes: 5),
    );
    expect(find.text('What did not work'), findsNothing);
    await _tap(tester, 'Close');
    await _until(tester, find.text('Tidy up'));
    say('UNDONE');
  }, timeout: const Timeout(Duration(minutes: 20)));
}

Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 90),
}) => _untilTrue(
  tester,
  () => finder.evaluate().isNotEmpty,
  timeout: timeout,
  what: '$finder',
);

Future<void> _untilTrue(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 90),
  String what = 'condition',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('not met after $timeout: $what');
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
