import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_tester.dart';
import '../../support/fake_native.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/scenarios.dart';

/// The result, interrupted cleanup and history screens
/// (docs/stage2_android.md, 5.21) on a fake phone whose files survive
/// restarts of the app.
void main() {
  late FakeDevice device;
  late InMemoryFileSource files;

  setUp(() async {
    InMemoryFileSource? shared;
    device = FakeDevice(
      restartable: true,
      files: (source) =>
          files = shared ??= InMemoryFileSource(sourceId: source.id)
            ..withTypicalDownloadFolder(),
    )..access.allFiles = true;
    await device.fixFolderNames();
  });

  Future<void> cleanUp(WidgetTester tester) async {
    await tester.tapText('Tidy up');
    await tester.settleUntil(find.text('Apply'));
    await tester.tapText('Apply');
    await tester.settleUntil(find.text('Close'));
  }

  /// Confirms the undo dialog.
  Future<void> confirm(WidgetTester tester, String button) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(button),
      ),
    );
    await tester.settle();
  }

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.byTooltip('History'));
    await tester.settle();
  }

  testWidgets('the result: counts, then "Undo the cleanup" with a dialog', (
    tester,
  ) async {
    await tester.pumpApp(device);
    final before = files.snapshot().tree;
    await cleanUp(tester);
    expect(find.text('Cleanup done'), findsOneWidget);
    expect(find.textContaining('Done: '), findsOneWidget);
    expect(find.textContaining('Freed: '), findsOneWidget);

    await tester.tapText('Undo the cleanup');
    expect(find.text('Bring the files back?'), findsOneWidget);
    await confirm(tester, 'Cancel');
    expect(find.text('Cleanup done'), findsOneWidget);
    expect(files.snapshot().tree, isNot(before));

    await tester.tapText('Undo the cleanup');
    await confirm(tester, 'Bring back');
    await tester.settleUntil(find.text('Cleanup undone'));
    expect(find.textContaining('Brought back: '), findsOneWidget);
    expect(find.text('Undo the cleanup'), findsNothing);
    expect(files.snapshot().tree, before);
    await tester.tapText('Close');
    expect(find.text('Tidy up'), findsOneWidget);
  });

  testWidgets('a failure is listed with its reason', (tester) async {
    await tester.pumpApp(device);
    files.failOn(
      FileErrorKind.locked,
      methods: {FsMethod.move},
      path: 'Download/notes.txt',
    );
    await cleanUp(tester);
    expect(find.text('Failed: 1'), findsOneWidget);
    expect(find.text('What did not work'), findsOneWidget);
    expect(find.text('Download/notes.txt'), findsOneWidget);
    expect(find.textContaining('In use by another app'), findsOneWidget);
  });

  group('an interrupted cleanup', () {
    /// The app dies while moving notes.txt; the file is gone from its new
    /// place before the app starts again.
    Future<void> interruptAndRestart(WidgetTester tester) async {
      await tester.runAsync(() async {
        final dying = ProviderContainer(overrides: device.overrides);
        await dying.read(appControllerProvider.notifier).start();
        final actions = dying.read(cleanupActionsProvider);
        await actions.plan();
        files.crashOn(
          methods: {FsMethod.move},
          path: 'Download/notes.txt',
          point: CrashPoint.afterEffect,
        );
        await expectLater(actions.apply(), throwsA(isA<SimulatedCrash>()));
        dying.dispose();
        files
          ..clearFaults()
          ..removeExternally('Documents/notes.txt');
      });
      await tester.pumpApp(device);
    }

    testWidgets('found at start; the lost file needs attention', (
      tester,
    ) async {
      await interruptAndRestart(tester);
      expect(find.text('The last cleanup was interrupted'), findsOneWidget);
      expect(find.text('1 operation sorted out'), findsOneWidget);
      expect(find.textContaining('Needs attention'), findsOneWidget);
      final path = tester.widget<Text>(find.text('Download/notes.txt'));
      expect(path.style?.color, isNotNull);
      for (final button in ['Finish the cleanup', 'Undo it', 'Not now']) {
        expect(find.text(button), findsOneWidget);
      }
    });

    testWidgets('"Undo it" asks, then brings back what it can; the lost '
        'file stays a problem', (tester) async {
      await interruptAndRestart(tester);
      await tester.tapText('Undo it');
      expect(find.text('Bring the files back?'), findsOneWidget);
      await confirm(tester, 'Bring back');
      await tester.settleUntil(find.text('Close'));
      expect(find.text('Cleanup undone'), findsOneWidget);
      expect(find.textContaining('Needs attention'), findsOneWidget);
      expect(files.isFile('Download/notes.txt'), isFalse);
      await tester.tapText('Close');
      expect(find.text('Tidy up'), findsOneWidget);
    });

    testWidgets('"Not now" goes home; the cleanup is in the history', (
      tester,
    ) async {
      await interruptAndRestart(tester);
      await tester.tapText('Not now');
      expect(find.text('Tidy up'), findsOneWidget);
      await openHistory(tester);
      expect(find.textContaining('Finished with errors'), findsOneWidget);
    });

    testWidgets('"Finish the cleanup" makes a new plan', (tester) async {
      await interruptAndRestart(tester);
      await tester.tapText('Finish the cleanup');
      await tester.settleUntil(find.text('Cleanup plan'));
      expect(find.text('Cleanup plan'), findsOneWidget);
    });
  });

  group('the history', () {
    testWidgets('empty at first', (tester) async {
      await tester.pumpApp(device);
      await openHistory(tester);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('No cleanups yet'), findsOneWidget);
    });

    testWidgets('a cleanup opens with its groups and files; undo a group '
        'asks, closes the history and shows the result', (tester) async {
      await tester.pumpApp(device);
      await cleanUp(tester);
      await tester.tapText('Close');
      await openHistory(tester);
      await tester.tap(find.byType(ListTile).first);
      await tester.settle();
      expect(find.textContaining('Cleanup of '), findsOneWidget);
      expect(find.text('Duplicates'), findsOneWidget);
      await tester.reveal(find.text('To Documents'));
      expect(find.text('To Documents'), findsOneWidget);

      final group = find.descendant(
        of: find.ancestor(
          of: find.text('To Documents'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('Bring this group back'),
      );
      await tester.reveal(group);
      await tester.tap(group);
      await tester.settle();
      expect(find.text('5 files go back where they were.'), findsOneWidget);
      await confirm(tester, 'Bring back');
      await tester.settleUntil(find.text('Cleanup partly undone'));
      expect(find.text('Cleanup partly undone'), findsOneWidget);
      expect(files.isFile('Download/notes.txt'), isTrue);
      expect(files.isFile('Music/song.mp3'), isTrue);
      await tester.tapText('Close');
      expect(find.text('Tidy up'), findsOneWidget);
    });

    testWidgets('one file comes back without a dialog', (tester) async {
      await tester.pumpApp(device);
      await cleanUp(tester);
      await tester.tapText('Close');
      // The card of the last cleanup opens it too.
      await tester.tapText('Done');
      final song = find.descendant(
        of: find.ancestor(
          of: find.text('song.mp3'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('Bring back'),
      );
      await tester.reveal(song);
      await tester.tap(song);
      await tester.settleUntil(find.text('Close'));
      expect(find.text('Bring the files back?'), findsNothing);
      expect(files.isFile('Download/song.mp3'), isTrue);
      expect(files.isFile('Download/notes.txt'), isFalse);
    });

    testWidgets('a purged quarantine is marked and cannot come back', (
      tester,
    ) async {
      final settings = DriftSettingsRepository(device.database);
      await settings.save(
        (await settings.load()).copyWith(
          quarantineRetention: Settings.minQuarantineRetention,
        ),
      );
      await tester.pumpApp(device);
      await cleanUp(tester);
      await tester.tapText('Close');
      device.clock.advance(const Duration(days: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpApp(device);
      await openHistory(tester);
      await tester.tap(find.byType(ListTile).first);
      await tester.settle();
      expect(
        find.text('Quarantine emptied: cannot be brought back'),
        findsWidgets,
      );
      final duplicate = find.ancestor(
        of: find.text('invoice_2024 (1).pdf'),
        matching: find.byType(ListTile),
      );
      await tester.reveal(duplicate);
      expect(
        find.descendant(of: duplicate, matching: find.text('Bring back')),
        findsNothing,
      );
    });
  });

  testWidgets('in Russian', (tester) async {
    device.languages = const ['ru'];
    await tester.pumpApp(device);
    await tester.tapText('Навести порядок');
    await tester.settleUntil(find.text('Применить'));
    await tester.tapText('Применить');
    await tester.settleUntil(find.text('Готово'));
    expect(find.text('Уборка завершена'), findsOneWidget);
    await tester.tapText('Отменить уборку');
    expect(find.text('Вернуть файлы?'), findsOneWidget);
    await confirm(tester, 'Вернуть');
    await tester.settleUntil(find.text('Уборка отменена'));
    expect(find.text('Уборка отменена'), findsOneWidget);
  });
}
