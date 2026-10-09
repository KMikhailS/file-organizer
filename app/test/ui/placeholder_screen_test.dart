import 'package:file_organizer/ui/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

/// The temporary screen of tasks 10 and 11 on a fake device.
void main() {
  // Database and file work run outside the fake clock of the test.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester, FakeDevice device) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: device.overrides,
        child: const FileOrganizerApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('first start: access, folder names, then a plan; there is no '
      'way to apply it', (tester) async {
    final device = FakeDevice();
    await pumpApp(tester, device);
    expect(find.text('Grant access'), findsOneWidget);

    device.access.grantOnRequest = true;
    await tester.tap(find.text('Grant access'));
    await settle(tester);
    expect(find.text('Folders for your files'), findsOneWidget);
    for (final name in ['Documents', 'Photos', 'Installers', 'Other']) {
      expect(find.text(name), findsOneWidget);
    }

    await tester.ensureVisible(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await settle(tester);
    expect(find.text('Ready'), findsOneWidget);

    await tester.tap(find.text('Make a plan'));
    for (
      var i = 0;
      i < 20 && find.textContaining('Plan ready').evaluate().isEmpty;
      i++
    ) {
      await settle(tester);
    }
    expect(find.textContaining('Plan ready'), findsOneWidget);
    expect(find.textContaining('Apply'), findsNothing);

    await tester.tap(find.text('Dismiss plan'));
    await settle(tester);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('a phone in Russian: Russian texts and folder names', (
    tester,
  ) async {
    final device = FakeDevice()..languages = const ['ru-RU'];
    await pumpApp(tester, device);
    expect(find.text('Дать доступ'), findsOneWidget);

    device.access.grantOnRequest = true;
    await tester.tap(find.text('Дать доступ'));
    await settle(tester);
    expect(find.text('Папки для ваших файлов'), findsOneWidget);
    for (final name in ['Документы', 'Фото', 'Установщики', 'Другое']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Documents'), findsNothing);
  });

  testWidgets('the phone switches its language: the screen follows', (
    tester,
  ) async {
    final device = FakeDevice();
    await pumpApp(tester, device);
    expect(find.text('Grant access'), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('ru', 'RU')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await settle(tester);
    expect(find.text('Дать доступ'), findsOneWidget);
  });
}
