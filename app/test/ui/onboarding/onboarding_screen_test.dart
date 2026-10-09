import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_tester.dart';
import '../../support/fake_native.dart';
import '../../support/folder_names.dart';

/// The onboarding of the first start (docs/stage2_android.md, 5.17).
void main() {
  late FakeDevice device;

  setUp(() => device = FakeDevice());

  Future<Map<Category, String>?> savedNames() async =>
      (await DriftSettingsRepository(device.database).load()).layoutFolderNames;

  testWidgets('the whole way: intro, access, notifications, folder names, '
      'then home', (tester) async {
    device.access
      ..grantOnRequest = true
      ..notifications = false
      ..allowNotificationsOnRequest = true;
    await tester.pumpApp(device);

    expect(find.text('Order in your files'), findsOneWidget);
    expect(find.text('Nothing is deleted'), findsOneWidget);
    await tester.tapText('Next');

    expect(find.text('Access to your files'), findsOneWidget);
    expect(find.textContaining('not granted'), findsNothing);
    await tester.tapText('Grant access');
    expect(device.access.requests, 1);

    expect(find.text('Notifications'), findsOneWidget);
    await tester.tapText('Allow notifications');
    expect(device.access.notificationRequests, 1);

    expect(find.text('Folders for your files'), findsOneWidget);
    expect(find.text('Installers (APK)'), findsOneWidget);
    expect(await savedNames(), isNull);
    await tester.tapText('Confirm');

    expect(find.text('Tidy up'), findsOneWidget);
    expect(await savedNames(), englishNames);
  });

  testWidgets('access refused: the step stays and says so; granted later in '
      'the settings, the onboarding goes on', (tester) async {
    await tester.pumpApp(device);
    await tester.tapText('Next');
    await tester.tapText('Grant access');
    expect(device.access.requests, 1);
    expect(find.text('Access to your files'), findsOneWidget);
    expect(find.textContaining('not granted yet'), findsOneWidget);

    // The user turns the switch on in the system settings and comes back.
    device.access.allFiles = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.settle();
    expect(find.text('Folders for your files'), findsOneWidget);
  });

  testWidgets('notifications refused: the user may go on without them', (
    tester,
  ) async {
    device.access
      ..allFiles = true
      ..notifications = false;
    await tester.pumpApp(device);
    await tester.tapText('Next');
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Continue without them'), findsNothing);

    await tester.tapText('Allow notifications');
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    await tester.tapText('Continue without them');
    expect(find.text('Folders for your files'), findsOneWidget);
  });

  testWidgets('notifications allowed in the system settings meanwhile: the '
      'step goes on returning', (tester) async {
    device.access
      ..allFiles = true
      ..notifications = false;
    await tester.pumpApp(device);
    await tester.tapText('Next');
    expect(find.text('Notifications'), findsOneWidget);

    device.access.notifications = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.settle();
    expect(find.text('Folders for your files'), findsOneWidget);
    expect(device.access.notificationRequests, 0);
  });

  testWidgets('steps already done are skipped (access and notifications '
      'granted, as after a restart)', (tester) async {
    device.access.allFiles = true;
    await tester.pumpApp(device);
    await tester.tapText('Next');
    expect(find.text('Folders for your files'), findsOneWidget);
    expect(device.access.requests, 0);
    expect(device.access.notificationRequests, 0);
  });

  group('folder names', () {
    setUp(() => device.access.allFiles = true);

    Future<void> openStep(WidgetTester tester) async {
      await tester.pumpApp(device);
      await tester.tapText('Next');
    }

    Finder field(Category category) => find.byKey(ValueKey(category));

    Future<void> type(
      WidgetTester tester,
      Category category,
      String text,
    ) async {
      await tester.ensureVisible(field(category));
      await tester.enterText(field(category), text);
      await tester.pumpAndSettle();
    }

    bool confirmEnabled(WidgetTester tester) => tester
        .widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text('Confirm'),
            matching: find.bySubtype<ButtonStyleButton>(),
          ),
        )
        .enabled;

    testWidgets('a wrong name is explained and blocks the confirmation', (
      tester,
    ) async {
      await openStep(tester);
      expect(confirmEnabled(tester), isTrue);
      const cases = {
        '': 'Enter a name',
        '   ': 'Enter a name',
        'Photos/2024': 'A name cannot contain',
        'What?': 'A name cannot contain',
        '.hidden': 'A name cannot start with a dot',
        'documents': 'This name is already used',
      };
      for (final MapEntry(key: text, value: message) in cases.entries) {
        await type(tester, Category.photos, text);
        expect(find.textContaining(message), findsOneWidget, reason: text);
        expect(confirmEnabled(tester), isFalse, reason: text);
      }
      await type(tester, Category.photos, 'x' * 65);
      expect(find.text('At most 64 characters'), findsOneWidget);

      await type(tester, Category.photos, 'Photos');
      expect(confirmEnabled(tester), isTrue);
      expect(await savedNames(), isNull);
    });

    testWidgets('changed names are saved trimmed and used from then on', (
      tester,
    ) async {
      await openStep(tester);
      await type(tester, Category.photos, '  Camera roll ');
      await type(tester, Category.installers, 'APK');
      await tester.tapText('Confirm');
      expect(find.text('Tidy up'), findsOneWidget);
      expect(await savedNames(), {
        ...englishNames,
        Category.photos: 'Camera roll',
        Category.installers: 'APK',
      });
    });
  });

  testWidgets('a phone in Russian: the onboarding speaks Russian', (
    tester,
  ) async {
    device
      ..languages = const ['ru-RU']
      ..access.allFiles = true;
    await tester.pumpApp(device);
    expect(find.text('Порядок в ваших файлах'), findsOneWidget);
    await tester.tapText('Далее');
    expect(find.text('Папки для ваших файлов'), findsOneWidget);
    expect(find.text('Установщики (APK)'), findsOneWidget);
    await tester.tapText('Подтвердить');
    expect(find.text('Навести порядок'), findsOneWidget);
    expect(await savedNames(), russianNames);
  });
}
