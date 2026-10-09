import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../support/app_tester.dart';
import '../../support/fake_native.dart';

/// The home screen after the first start (docs/stage2_android.md, 5.17).
void main() {
  late FakeDevice device;

  setUp(() async {
    device = FakeDevice()..access.allFiles = true;
    await device.fixFolderNames();
  });

  Future<void> saveSession(
    SessionStatus status,
    SessionStats stats, {
    String id = 's1',
    DateTime? at,
  }) => DriftSessionRepository(device.database).save(
    CleanupSession(
      id: SessionId(id),
      startedAt: (at ?? DateTime.utc(2026, 10, 9, 9)).subtract(
        const Duration(minutes: 1),
      ),
      finishedAt: at ?? DateTime.utc(2026, 10, 9, 9),
      status: status,
      stats: stats,
    ),
  );

  bool tidyUpEnabled(WidgetTester tester) => tester
      .widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Tidy up'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      )
      .enabled;

  testWidgets('no cleanups yet: the button is ready', (tester) async {
    await tester.pumpApp(device);
    expect(find.text('Tidy up'), findsOneWidget);
    expect(tidyUpEnabled(tester), isTrue);
    expect(find.text('No cleanups yet'), findsOneWidget);
    expect(find.text('No access to your files'), findsNothing);
  });

  testWidgets('the last cleanup: date, status and counts', (tester) async {
    await saveSession(
      SessionStatus.completed,
      SessionStats(
        total: 2,
        done: 2,
        failed: 0,
        skipped: 0,
        reverted: 0,
        revertSkipped: 0,
        removedBytes: 1500000,
      ),
      id: 'old',
      at: DateTime.utc(2026, 10, 2),
    );
    final at = DateTime.utc(2026, 10, 9, 9, 30);
    await saveSession(
      SessionStatus.completed,
      SessionStats(
        total: 7,
        done: 5,
        failed: 1,
        skipped: 1,
        reverted: 0,
        revertSkipped: 0,
        removedBytes: 1500000,
      ),
      at: at,
    );
    await tester.pumpApp(device);
    final date = DateFormat.yMMMd('en').add_Hm().format(at.toLocal());
    expect(find.text('Last cleanup: $date'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('5 of 7 operations done'), findsOneWidget);
    expect(find.text('2 operations skipped or failed'), findsOneWidget);
    expect(find.text('Freed: 1.5 MB'), findsOneWidget);
  });

  testWidgets('an undone cleanup says so; nothing freed any more', (
    tester,
  ) async {
    await saveSession(
      SessionStatus.reverted,
      SessionStats(
        total: 3,
        done: 0,
        failed: 0,
        skipped: 0,
        reverted: 3,
        revertSkipped: 0,
        removedBytes: 0,
      ),
    );
    await tester.pumpApp(device);
    expect(find.text('Undone: everything is back'), findsOneWidget);
    expect(find.text('3 of 3 operations done'), findsOneWidget);
    expect(find.text('3 operations undone'), findsOneWidget);
    expect(find.textContaining('Freed'), findsNothing);
  });

  testWidgets('a session still running is not the last cleanup', (
    tester,
  ) async {
    final repository = DriftSessionRepository(device.database);
    final planned = CleanupSession(
      id: const SessionId('planned'),
      startedAt: DateTime.utc(2026, 10, 9),
      status: SessionStatus.planned,
      stats: SessionStats.empty,
    );
    await repository.save(planned);
    await tester.pumpApp(device);
    expect(find.text('No cleanups yet'), findsOneWidget);
  });

  testWidgets('access taken back: a banner, the button waits; granted again, '
      'all is back', (tester) async {
    device.access
      ..allFiles = false
      ..grantOnRequest = true;
    await tester.pumpApp(device);
    expect(find.text('No access to your files'), findsOneWidget);
    expect(find.text('Order in your files'), findsNothing);
    expect(tidyUpEnabled(tester), isFalse);

    await tester.tapText('Grant access');
    expect(find.text('No access to your files'), findsNothing);
    expect(tidyUpEnabled(tester), isTrue);
  });

  testWidgets('"Tidy up" plans on the temporary work screen; dismissing '
      'comes back home; nothing can be applied', (tester) async {
    await tester.pumpApp(device);
    await tester.tapText('Tidy up');
    await tester.settleUntil(find.textContaining('Plan ready'));
    expect(find.textContaining('Plan ready'), findsOneWidget);
    expect(find.textContaining('Apply'), findsNothing);

    await tester.tapText('Dismiss');
    expect(find.text('Tidy up'), findsOneWidget);
  });

  testWidgets('in Russian', (tester) async {
    device.languages = const ['ru'];
    await tester.pumpApp(device);
    expect(find.text('Навести порядок'), findsOneWidget);
    expect(find.text('Уборок ещё не было'), findsOneWidget);
  });
}
