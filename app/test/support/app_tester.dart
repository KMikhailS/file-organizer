import 'package:file_organizer/ui/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_native.dart';

/// Widget tests of the whole app on a [FakeDevice].
extension AppTester on WidgetTester {
  /// Starts the app on [device] and waits until it settles.
  Future<void> pumpApp(FakeDevice device) async {
    await pumpWidgetOnly(device);
    await settle();
  }

  /// Puts the app on [device] on screen without waiting for its start.
  Future<void> pumpWidgetOnly(FakeDevice device) async {
    // A phone screen: the steps lay out as on a device.
    view.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 2.75;
    addTearDown(view.reset);
    await pumpWidget(
      ProviderScope(
        overrides: device.overrides,
        child: const FileOrganizerApp(),
      ),
    );
  }

  /// Lets the database and file work (which run outside the fake clock of
  /// the test) finish, then settles the frames.
  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await runAsync(() => Future<void>.delayed(Duration.zero));
      await pumpAndSettle();
    }
  }

  /// Taps the widget with [text] (scrolled into view) and settles.
  Future<void> tapText(String text) async {
    await reveal(find.text(text));
    await tap(find.text(text));
    await settle();
  }

  /// Scrolls [finder] into view. Lazy lists build only the rows on screen,
  /// so it scrolls the first list down, then up, until the widget exists.
  Future<void> reveal(Finder finder) async {
    final lists = find.byType(Scrollable);
    for (final delta in [200.0, -200.0]) {
      if (finder.evaluate().isNotEmpty || lists.evaluate().isEmpty) {
        break;
      }
      try {
        await scrollUntilVisible(finder, delta, scrollable: lists.first);
      } on StateError {
        // Not in this direction.
      }
    }
    await ensureVisible(finder);
    await pumpAndSettle();
  }

  /// Settles until [finder] finds something, for work that takes a few
  /// rounds (a scan).
  Future<void> settleUntil(Finder finder, {int rounds = 30}) async {
    for (var i = 0; i < rounds && finder.evaluate().isEmpty; i++) {
      await settle();
    }
  }
}
