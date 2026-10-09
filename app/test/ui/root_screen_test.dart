import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_tester.dart';
import '../support/fake_native.dart';

/// Which screen the app shows (docs/stage2_android.md, 5.17).
void main() {
  testWidgets('the first start goes to the onboarding, even with access', (
    tester,
  ) async {
    final device = FakeDevice()..access.allFiles = true;
    await tester.pumpApp(device);
    expect(find.text('Order in your files'), findsOneWidget);
  });

  testWidgets('a later start goes home', (tester) async {
    final device = FakeDevice()..access.allFiles = true;
    await device.fixFolderNames();
    await tester.pumpApp(device);
    expect(find.text('Tidy up'), findsOneWidget);
  });

  testWidgets('a failed start shows why and starts again', (tester) async {
    final device = FakeDevice()..access.allFiles = true;
    await device.fixFolderNames();
    device.storage.root = null;
    await tester.pumpApp(device);
    expect(find.text('The app could not start'), findsOneWidget);
    expect(find.textContaining('not mounted'), findsOneWidget);

    device.storage.root = '/storage/emulated/0';
    await tester.tapText('Try again');
    expect(find.text('Tidy up'), findsOneWidget);
  });

  testWidgets('the splash while the start waits', (tester) async {
    final device = FakeDevice();
    await tester.pumpWidgetOnly(device);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.settle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
