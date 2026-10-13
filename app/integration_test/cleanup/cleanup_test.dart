// The plan applied through the real UI on an emulator
// (docs/stage2_android.md, 5.19). Run it with run_android.sh, never on its
// own: the script refuses any device but an emulator, puts the test files
// into Download/, grants the permissions, and checks the tree afterwards.
//
// The app (clean install) goes through the onboarding, plans, the test
// unchecks the music, applies, checks the files on disk, then undoes
// through the UI: one group from the history, then the rest of the
// cleanup, and checks that every file is back.
import 'dart:io';

import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/app.dart';
import 'package:file_organizer/ui/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String storage = '/storage/emulated/0';
const String download = '$storage/Download';

void say(String what) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('CLEANUP|$what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plan, approve, apply, undo on real storage', (tester) async {
    for (final name in [
      'fo13_report.pdf',
      'fo13_report (1).pdf',
      'fo13_song.mp3',
      'fo13_photo.jpg',
      'fo13_archive.zip',
    ]) {
      expect(File('$download/$name').existsSync(), isTrue, reason: name);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(AppServices.android()),
          ...localizationOverrides(),
        ],
        child: const FileOrganizerApp(),
      ),
    );

    await _tap(tester, 'Next');
    await _tap(tester, 'Confirm');
    await _tap(tester, 'Tidy up');
    await _until(
      tester,
      find.text('Cleanup plan'),
      timeout: const Duration(minutes: 3),
    );
    say('PLAN');

    for (final title in [
      'To Documents: 1',
      'To Music: 1',
      'To Photos / 2021: 1',
      'To Archives: 1',
    ]) {
      await _reveal(tester, find.text(title));
    }
    await _reveal(tester, find.textContaining('Duplicates: 1 file'));

    // The photo has a thumbnail from MediaStore.
    await _tap(tester, 'To Photos / 2021: 1');
    await _until(tester, find.byKey(const ValueKey('thumbnail')));
    say('THUMBNAIL');

    // Keep the music where it is.
    final music = find.descendant(
      of: find.ancestor(
        of: find.text('To Music: 1'),
        matching: find.byType(ListTile),
      ),
      matching: find.byType(Checkbox),
    );
    await _reveal(tester, music);
    await tester.tap(music);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<Checkbox>(music).value, isFalse);

    await _tap(tester, 'Apply');
    await _until(
      tester,
      find.text('Cleanup done'),
      timeout: const Duration(minutes: 2),
    );
    say('APPLIED');

    expect(File('$storage/Documents/fo13_report.pdf').existsSync(), isTrue);
    expect(File('$storage/Photos/2021/fo13_photo.jpg').existsSync(), isTrue);
    expect(File('$storage/Archives/fo13_archive.zip').existsSync(), isTrue);
    expect(File('$download/fo13_song.mp3').existsSync(), isTrue);
    expect(File('$download/fo13_report (1).pdf').existsSync(), isFalse);
    expect(File('$download/fo13_report.pdf').existsSync(), isFalse);
    expect(Directory('$storage/.FileOrganizer').existsSync(), isTrue);
    await _tap(tester, 'Close');

    // One group back from the history, with its dialog.
    await _tap(tester, 'History');
    await _until(tester, find.byType(ListTile));
    await tester.tap(find.byType(ListTile).first);
    await tester.pump(const Duration(milliseconds: 300));
    final documents = find.descendant(
      of: find.ancestor(
        of: find.text('To Documents'),
        matching: find.byType(ListTile),
      ),
      matching: find.text('Bring this group back'),
    );
    await _until(tester, find.text('To Documents'));
    await _reveal(tester, documents);
    await tester.tap(documents);
    await _confirm(tester);
    await _until(tester, find.text('Cleanup partly undone'));
    expect(File('$download/fo13_report.pdf').existsSync(), isTrue);
    expect(File('$storage/Photos/2021/fo13_photo.jpg').existsSync(), isTrue);
    say('GROUP_UNDONE');
    await _tap(tester, 'Close');

    // The rest from the card of the last cleanup.
    await _tap(tester, 'Partly undone');
    await _tap(tester, 'Undo the whole cleanup');
    await _confirm(tester);
    await _until(tester, find.text('Cleanup undone'));
    await _tap(tester, 'Close');
    await _until(tester, find.text('Tidy up'));

    for (final name in [
      'fo13_report.pdf',
      'fo13_report (1).pdf',
      'fo13_song.mp3',
      'fo13_photo.jpg',
      'fo13_archive.zip',
    ]) {
      expect(File('$download/$name').existsSync(), isTrue, reason: name);
    }
    expect(Directory('$storage/Photos').existsSync(), isFalse);
    expect(Directory('$storage/Archives').existsSync(), isFalse);
    say('UNDONE');
  }, timeout: const Timeout(Duration(minutes: 10)));
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

/// Scrolls the plan until [finder] is on screen (the list is lazy).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Confirms the undo dialog.
Future<void> _confirm(WidgetTester tester) async {
  final yes = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text('Bring back'),
  );
  await _until(tester, yes);
  await tester.tap(yes);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tap(WidgetTester tester, String text) async {
  final target = text == 'History' ? find.byTooltip(text) : find.text(text);
  await _until(tester, target);
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 300));
}
