import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_tester.dart';
import '../../support/fake_native.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/scenarios.dart';

/// The settings screen (docs/stage2_android.md, 5.23) on a fake phone with
/// a typical Download folder and the user's own Papers.
void main() {
  late FakeDevice device;

  setUp(() async {
    device = FakeDevice(
      files: (source) => InMemoryFileSource(sourceId: source.id)
        ..withTypicalDownloadFolder()
        ..withOrganizedDocumentArchive(root: 'Papers'),
    )..access.allFiles = true;
    await device.fixFolderNames();
  });

  DriftRuleRepository rules() => DriftRuleRepository(device.database);

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpApp(device);
    await tester.tap(find.byTooltip('Settings'));
    await tester.settle();
  }

  Future<void> dialogTap(WidgetTester tester, String text) async {
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => w is Dialog || w is AlertDialog),
        matching: find.text(text),
      ),
    );
    await tester.settle();
  }

  /// Picks a folder in the picker by tapping through [names].
  Future<void> pick(WidgetTester tester, List<String> names) async {
    for (final name in names) {
      await tester.tapText(name);
    }
    await tester.tapText('Choose this folder');
  }

  bool enabled(WidgetTester tester, String text) => tester
      .widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text(text),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      )
      .enabled;

  group('folder marks', () {
    testWidgets('a folder picked level by level, marked "leave alone"', (
      tester,
    ) async {
      await openSettings(tester);
      expect(find.text('No marks yet'), findsOneWidget);
      await tester.tapText('Mark a folder');
      expect(find.text('Choose a folder'), findsOneWidget);
      expect(find.text('The whole storage'), findsOneWidget);
      await tester.tapText('Papers');
      expect(find.text('Car'), findsOneWidget);
      // Back goes one level up, not out of the picker.
      await tester.pageBack();
      await tester.settle();
      expect(find.text('Choose a folder'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      await pick(tester, ['Download']);

      expect(find.text('What to do with Download?'), findsOneWidget);
      await dialogTap(tester, 'Leave alone');
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Leave alone'), findsOneWidget);
      expect(await rules().zoneOverrides(AppController.storageId), [
        ZoneOverride(
          sourceId: AppController.storageId,
          folder: LogicalPath('Download'),
          zone: Zone.organized,
        ),
      ]);

      await tester.reveal(find.byTooltip('Remove the mark'));
      await tester.tap(find.byTooltip('Remove the mark'));
      await tester.settle();
      expect(find.text('No marks yet'), findsOneWidget);
      expect(await rules().zoneOverrides(AppController.storageId), isEmpty);
    });

    testWidgets('"tidy up" warns first; cancelling saves nothing', (
      tester,
    ) async {
      await openSettings(tester);
      await tester.tapText('Mark a folder');
      await pick(tester, ['Papers', 'Car']);
      await dialogTap(tester, 'Tidy up');
      expect(
        find.textContaining('will be offered for sorting'),
        findsOneWidget,
      );
      await dialogTap(tester, 'Cancel');
      expect(await rules().zoneOverrides(AppController.storageId), isEmpty);

      await tester.tapText('Mark a folder');
      await pick(tester, ['Papers', 'Car']);
      await dialogTap(tester, 'Tidy up');
      await dialogTap(tester, 'Continue');
      expect(find.text('Papers / Car'), findsOneWidget);
      expect(
        (await rules().zoneOverrides(AppController.storageId)).single.zone,
        Zone.chaos,
      );
    });

    testWidgets('a template folder: the dialog says a mark does nothing', (
      tester,
    ) async {
      device = FakeDevice(
        files: (source) => InMemoryFileSource(sourceId: source.id)
          ..withTypicalDownloadFolder()
          ..addFile('Music/album/track.mp3'),
      )..access.allFiles = true;
      await device.fixFolderNames();
      await openSettings(tester);
      await tester.tapText('Mark a folder');
      await pick(tester, ['Music', 'album']);
      expect(find.textContaining('folder of the template'), findsOneWidget);
      await dialogTap(tester, 'Leave alone');

      await tester.tapText('Mark a folder');
      await pick(tester, []);
      expect(find.text('What to do with The whole storage?'), findsOneWidget);
      expect(find.textContaining('folder of the template'), findsNothing);
      await dialogTap(tester, 'Exclude');
      expect(find.text('The whole storage'), findsOneWidget);
    });
  });

  group('rules', () {
    testWidgets('a new rule needs a condition; saved with clean extensions', (
      tester,
    ) async {
      await openSettings(tester);
      await tester.tapText('Add a rule');
      expect(find.text('Set at least one condition'), findsOneWidget);
      expect(enabled(tester, 'Save'), isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('extensions')),
        'TXT, .md',
      );
      await tester.pumpAndSettle();
      expect(find.text('Set at least one condition'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('target')));
      await tester.settle();
      await tester.tap(find.text('Archives').last);
      await tester.settle();
      await tester.tapText('Save');

      final saved = await rules().classificationRules();
      expect(saved.single.extensions, {'txt', 'md'});
      expect(saved.single.category, Category.archives);
      expect(find.text('.md, .txt → Archives'), findsOneWidget);
    });

    testWidgets('a rule with a folder and "leave where it is"; edited in '
        'place', (tester) async {
      await openSettings(tester);
      await tester.tapText('Add a rule');
      await tester.enterText(find.byKey(const ValueKey('name')), 'scan');
      await tester.tapText('In folder');
      await pick(tester, ['Download']);
      await tester.tap(find.byKey(const ValueKey('target')));
      await tester.settle();
      await tester.tap(find.text('Leave where it is').last);
      await tester.settle();
      await tester.tapText('Save');
      expect(
        find.text('name contains «scan», in Download → Leave where it is'),
        findsOneWidget,
      );

      await tester.tapText(
        'name contains «scan», in Download → Leave where it is',
      );
      await tester.tap(find.byTooltip('Anywhere'));
      await tester.settle();
      await tester.tapText('Save');
      final saved = (await rules().classificationRules()).single;
      expect(saved.folder, isNull);
      expect(saved.nameContains, 'scan');
      expect(saved.category, Category.unresolved);
    });

    testWidgets('reordered with up and down; deleted', (tester) async {
      for (final (id, ext) in [('rule-a', 'txt'), ('rule-b', 'mp3')]) {
        await rules().saveClassificationRule(
          ClassificationRule(
            id: id,
            category: Category.other,
            priority: id == 'rule-a' ? 0 : 10,
            extensions: {ext},
          ),
        );
      }
      await openSettings(tester);
      final ups = find.widgetWithIcon(IconButton, Icons.arrow_upward);
      expect(tester.widget<IconButton>(ups.first).onPressed, isNull);
      await tester.tap(ups.last);
      await tester.settle();
      expect(
        [for (final r in await rules().classificationRules()) r.id],
        ['rule-b', 'rule-a'],
      );
      await tester.tap(find.byTooltip('Delete').first);
      await tester.settle();
      expect(
        [for (final r in await rules().classificationRules()) r.id],
        ['rule-a'],
      );
    });
  });

  group('quarantine', () {
    testWidgets('a shorter retention warns; a longer one does not', (
      tester,
    ) async {
      await openSettings(tester);
      final settings = DriftSettingsRepository(device.database);
      await tester.tapText('7 days');
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('deleted for good'),
        ),
        findsOneWidget,
      );
      await dialogTap(tester, 'Cancel');
      expect(
        (await settings.load()).quarantineRetention,
        const Duration(days: 30),
      );

      await tester.tapText('7 days');
      await dialogTap(tester, 'Continue');
      expect(
        (await settings.load()).quarantineRetention,
        const Duration(days: 7),
      );

      await tester.tapText('90 days');
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        (await settings.load()).quarantineRetention,
        const Duration(days: 90),
      );
    });
  });

  testWidgets('the language changes at once and is saved', (tester) async {
    await openSettings(tester);
    await tester.tapText('Русский');
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Язык'), findsOneWidget);
    expect(
      (await DriftSettingsRepository(device.database).load()).uiLocale,
      'ru',
    );
    await tester.tapText('Как в телефоне');
    expect(find.text('Settings'), findsOneWidget);
    expect(
      (await DriftSettingsRepository(device.database).load()).uiLocale,
      isNull,
    );
  });

  testWidgets('permissions: what is granted, and buttons for the rest', (
    tester,
  ) async {
    device.access
      ..notifications = false
      ..allowNotificationsOnRequest = true;
    await openSettings(tester);
    await tester.reveal(find.text('Permissions'));
    expect(find.text('Granted'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    await tester.tapText('Allow notifications');
    expect(find.text('On'), findsOneWidget);
    expect(device.access.notificationRequests, 1);
  });
}
