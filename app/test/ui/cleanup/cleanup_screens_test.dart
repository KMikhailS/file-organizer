import 'dart:async';
import 'dart:convert';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/cleanup/plan_failed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_tester.dart';
import '../../support/fake_native.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/scenarios.dart';

/// The progress and plan screens (docs/stage2_android.md, 5.19) on a fake
/// phone: a typical Download folder, duplicate photos, and two equal files
/// in the user's own Documents.
void main() {
  late FakeDevice device;
  late InMemoryFileSource files;

  /// Holds the work at the first call of [method] until completed.
  Completer<void> holdAt(FsMethod method) {
    final gate = Completer<void>();
    var held = false;
    files.beforeCall = (call) async {
      if (call.method == method && !held) {
        held = true;
        await gate.future;
      }
    };
    return gate;
  }

  setUp(() async {
    device = FakeDevice(
      files: (source) => files = InMemoryFileSource(sourceId: source.id)
        ..withTypicalDownloadFolder()
        ..withPhoneDuplicatePhotos()
        ..addFile('Documents/Tax/receipt.pdf', text: 'receipt 42')
        ..addFile('Documents/Old/receipt copy.pdf', text: 'receipt 42'),
    )..access.allFiles = true;
    await device.fixFolderNames();
  });

  Future<void> openPlan(WidgetTester tester) async {
    await tester.pumpApp(device);
    await tester.tapText('Tidy up');
    await tester.settleUntil(find.text('Cleanup plan'));
    expect(find.text('Cleanup plan'), findsOneWidget);
  }

  Finder groupCheckbox(String title) => find.descendant(
    of: find.ancestor(
      of: find.textContaining(title),
      matching: find.byType(ListTile),
    ),
    matching: find.byType(Checkbox),
  );

  bool? checked(WidgetTester tester, String title) =>
      tester.widget<Checkbox>(groupCheckbox(title)).value;

  bool applyEnabled(WidgetTester tester) => tester
      .widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Apply'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      )
      .enabled;

  Future<void> tapCheckbox(WidgetTester tester, String title) async {
    await tester.reveal(groupCheckbox(title));
    await tester.tap(groupCheckbox(title));
    await tester.settle();
  }

  testWidgets('the plan: summary, groups, what stays where it is', (
    tester,
  ) async {
    await openPlan(tester);
    expect(find.textContaining('files will be tidied up'), findsOneWidget);
    expect(find.textContaining('will be freed'), findsOneWidget);
    expect(find.textContaining('Duplicates: 4 files'), findsOneWidget);
    expect(find.text('To Documents: 5'), findsOneWidget);
    for (final title in ['To Photos / 2024: 1', 'To Music: 1']) {
      await tester.reveal(find.text(title));
      expect(find.text(title), findsOneWidget);
    }
    await tester.reveal(
      find.textContaining('more copy is in your own folders'),
    );
    await tester.reveal(find.text('Not sorted: 2 files'));
    expect(find.text('Not sorted: 2 files'), findsOneWidget);
    expect(
      find.textContaining('Not everything could be checked'),
      findsNothing,
    );
    expect(applyEnabled(tester), isTrue);
  });

  testWidgets('a group opens to its files: where from, why, thumbnails for '
      'photos only', (tester) async {
    // A 1x1 PNG.
    device.thumbnails['Download/IMG_20240512_101500.jpg'] = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
      '60e6kgAAAABJRU5ErkJggg==',
    );
    await openPlan(tester);
    await tester.tapText('To Photos / 2024: 1');
    expect(find.text('IMG_20240512_101500.jpg'), findsOneWidget);
    expect(find.textContaining('From Download'), findsOneWidget);
    expect(find.textContaining('By extension .jpg'), findsOneWidget);
    expect(find.byKey(const ValueKey('thumbnail')), findsOneWidget);

    await tester.tapText('To Documents: 5');
    await tester.reveal(find.text('notes.txt'));
    expect(find.text('notes.txt'), findsOneWidget);
    expect(device.thumbnailRequests, ['Download/IMG_20240512_101500.jpg']);

    await tester.tapText('To Documents: 5');
    expect(find.text('notes.txt'), findsNothing);
  });

  testWidgets('unchecking a group, then a file; nothing selected disables '
      '"Apply"', (tester) async {
    await openPlan(tester);
    expect(checked(tester, 'Duplicates'), isTrue);
    await tapCheckbox(tester, 'Duplicates');
    expect(checked(tester, 'Duplicates'), isFalse);
    expect(find.textContaining('will be freed'), findsNothing);

    await tester.tapText('To Documents: 5');
    final notes = find.ancestor(
      of: find.text('notes.txt'),
      matching: find.byType(CheckboxListTile),
    );
    await tester.reveal(notes);
    await tester.tap(notes);
    await tester.settle();
    await tester.reveal(groupCheckbox('To Documents'));
    expect(checked(tester, 'To Documents'), isNull);

    for (final title in [
      'Duplicates',
      'To Documents',
      'To Photos / 2023',
      'To Photos / 2024',
      'To Screenshots / 2024',
      'To Videos / 2024',
      'To Music',
      'To Archives',
      'To Installers',
    ]) {
      await tester.reveal(groupCheckbox(title));
      while (checked(tester, title) != false) {
        await tapCheckbox(tester, title);
      }
    }
    await tester.reveal(find.text('Nothing is selected'));
    expect(find.text('Nothing is selected'), findsOneWidget);
    expect(applyEnabled(tester), isFalse);
  });

  testWidgets('"Apply": progress, then the result; only the approved files '
      'moved', (tester) async {
    await openPlan(tester);
    await tapCheckbox(tester, 'To Music');
    final gate = holdAt(FsMethod.move);
    await tester.tapText('Apply');
    expect(find.text('Tidying up'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    gate.complete();
    await tester.settleUntil(find.text('Cleanup done'));
    expect(find.text('Cleanup done'), findsOneWidget);
    expect(find.textContaining('Done: '), findsOneWidget);
    expect(find.text('What did not work'), findsNothing);
    await tester.tapText('Close');
    expect(find.text('Tidy up'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(files.isFile('Download/song.mp3'), isTrue);
    expect(files.isFile('Documents/notes.txt'), isTrue);
    expect(files.isFile('Download/notes.txt'), isFalse);
    expect(files.quarantined, hasLength(4));
    expect(files.isFile('Documents/Old/receipt copy.pdf'), isTrue);
  });

  testWidgets('cancel while tidying up: stops after the current operation', (
    tester,
  ) async {
    await openPlan(tester);
    final gate = holdAt(FsMethod.move);
    await tester.tapText('Apply');
    await tester.tapText('Cancel');
    expect(find.text('Cancelling…'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    // A second tap cannot ask again.
    expect(
      tester
          .widget<ButtonStyleButton>(
            find.ancestor(
              of: find.text('Cancelling…'),
              matching: find.bySubtype<ButtonStyleButton>(),
            ),
          )
          .enabled,
      isFalse,
    );

    gate.complete();
    await tester.settleUntil(find.text('Cleanup stopped'));
    expect(find.text('Undo the cleanup'), findsOneWidget);
    await tester.tapText('Close');
    expect(find.text('Stopped'), findsOneWidget);
    expect(files.isFile('Download/notes.txt'), isTrue);
  });

  testWidgets('cancel while looking for duplicates: back home, nothing '
      'changed', (tester) async {
    await tester.pumpApp(device);
    final before = files.snapshot();
    final gate = holdAt(FsMethod.partialHash);
    await tester.tapText('Tidy up');
    expect(find.text('Looking for duplicates'), findsOneWidget);
    await tester.tapText('Cancel');
    expect(find.text('Cancelling…'), findsOneWidget);

    gate.complete();
    await tester.settleUntil(find.text('Tidy up'));
    expect(find.text('Tidy up'), findsOneWidget);
    expect(files.snapshot(), before);
  });

  testWidgets('"Decline" goes home and changes nothing', (tester) async {
    await openPlan(tester);
    final before = files.snapshot();
    await tester.tapText('Decline');
    expect(find.text('Tidy up'), findsOneWidget);
    expect(files.snapshot(), before);
  });

  testWidgets('after a cleanup there is nothing to do', (tester) async {
    await openPlan(tester);
    await tester.tapText('Apply');
    await tester.settleUntil(find.text('Close'));
    await tester.tapText('Close');
    await tester.tapText('Tidy up');
    await tester.settleUntil(find.text('Everything is in order'));
    expect(find.text('Everything is in order'), findsOneWidget);
    await tester.tapText('Back');
    expect(find.text('Tidy up'), findsOneWidget);
  });

  testWidgets('warnings: a folder that cannot be read, a file that cannot '
      'be hashed', (tester) async {
    await tester.pumpApp(device);
    files
      ..denyAccess('Pictures')
      ..failOn(
        FileErrorKind.ioError,
        methods: {FsMethod.partialHash, FsMethod.fullHash},
        path: 'Download/IMG_20240518_093000 (1).jpg',
        times: 100,
      );
    await tester.tapText('Tidy up');
    await tester.settleUntil(find.text('Cleanup plan'));
    await tester.reveal(find.text('Not everything could be checked'));
    expect(find.text('1 folder could not be read'), findsOneWidget);
    expect(find.textContaining('1 file could not be read'), findsOneWidget);
  });

  testWidgets('in Russian', (tester) async {
    device.languages = const ['ru'];
    await tester.pumpApp(device);
    await tester.tapText('Навести порядок');
    await tester.settleUntil(find.text('План уборки'));
    expect(find.textContaining('Дубли: 4 файла'), findsOneWidget);
    expect(find.text('В Documents: 5'), findsOneWidget);
    expect(find.text('Применить'), findsOneWidget);
    expect(find.text('Отказаться'), findsOneWidget);
  });

  testWidgets('a plan that failed says why', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: device.overrides,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlanFailedScreen(reason: 'database is locked'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not make a plan'), findsOneWidget);
    expect(find.text('Details: database is locked'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });
}
