import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

/// The temporary screen of task 10 on a fake device.
void main() {
  testWidgets('access, then a plan; there is no way to apply it', (
    tester,
  ) async {
    final device = FakeDevice();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appServicesProvider.overrideWithValue(device.services)],
        child: const FileOrganizerApp(),
      ),
    );
    // Database and file work run outside the fake clock of the test.
    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('Grant access'), findsOneWidget);

    device.access.grantOnRequest = true;
    await tester.tap(find.text('Grant access'));
    await settle();
    expect(find.text('Ready'), findsOneWidget);

    await tester.tap(find.text('Make a plan'));
    for (
      var i = 0;
      i < 20 && find.textContaining('Plan ready').evaluate().isEmpty;
      i++
    ) {
      await settle();
    }
    expect(find.textContaining('Plan ready'), findsOneWidget);
    expect(find.textContaining('Apply'), findsNothing);

    await tester.tap(find.text('Dismiss plan'));
    await settle();
    expect(find.text('Ready'), findsOneWidget);
  });
}
