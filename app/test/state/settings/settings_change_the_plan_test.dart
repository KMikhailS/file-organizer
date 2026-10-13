import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/history/history_providers.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/state/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_native.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/scenarios.dart';

/// The settings change the plan (docs/stage2_android.md, task 15): zone
/// marks, rules and their order, the quarantine retention, the language.
/// A phone with a typical Download folder and the user's own Documents.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevice device;
  late InMemoryFileSource files;
  late ProviderContainer app;

  Future<void> launch() async {
    app = ProviderContainer(overrides: device.overrides);
    addTearDown(app.dispose);
    await app.read(appControllerProvider.notifier).start();
  }

  setUp(() async {
    InMemoryFileSource? shared;
    device = FakeDevice(
      files: (source) =>
          files = shared ??= InMemoryFileSource(sourceId: source.id)
            ..withTypicalDownloadFolder()
            ..withOrganizedDocumentArchive(root: 'Papers'),
    )..access.allFiles = true;
    await device.fixFolderNames();
    await launch();
  });

  CleanupWorkflow workflow() => app.read(workflowProvider);

  /// Plans and returns where each file of the plan goes ("quarantine" for
  /// duplicates), then declines the plan.
  Future<Map<String, String>> plan() async {
    await workflow().start();
    final ready = workflow().state as PlanReady;
    final plan = ready.plans.single.plan;
    workflow().dismiss();
    return {
      for (final op in plan.operations)
        if (op.type.actsOnFile)
          op.fromPath!.value: op.toPath?.parent?.value ?? 'quarantine',
    };
  }

  Future<List<String>> unresolved() async {
    await workflow().start();
    final plan = (workflow().state as PlanReady).plans.single.plan;
    workflow().dismiss();
    return [for (final f in plan.unresolved) f.path.value];
  }

  ZoneMarks marks() => app.read(zoneMarksProvider.notifier);
  UserRules rules() => app.read(userRulesProvider.notifier);

  group('zone marks', () {
    test('"leave alone" takes the files of a folder out of the plan', () async {
      expect((await plan()).keys, contains('Download/notes.txt'));
      await marks().mark(LogicalPath('Download'), Zone.organized);
      expect(await app.read(zoneMarksProvider.future), hasLength(1));
      final planned = await plan();
      expect(planned.keys.where((p) => p.startsWith('Download/')), isEmpty);
      expect(files.isFile('Download/notes.txt'), isTrue);
    });

    test('"exclude" keeps the folder out of the scan', () async {
      await marks().mark(LogicalPath('Download'), Zone.excluded);
      expect(await plan(), isEmpty);
      expect(await unresolved(), isEmpty);
      final index = await app
          .read(repositoriesProvider)
          .index
          .byPath(AppController.storageId, LogicalPath('Download/notes.txt'));
      expect(index, isNull);
    });

    test('"tidy up" brings the user\'s own folder into the plan', () async {
      expect(
        (await plan()).keys.where((p) => p.startsWith('Papers/Car/')),
        isEmpty,
      );
      await marks().mark(LogicalPath('Papers/Car'), Zone.chaos);
      final planned = await plan();
      expect(
        planned.keys.where((p) => p.startsWith('Papers/Car/')),
        hasLength(3),
      );
      expect(planned.keys.where((p) => p.startsWith('Papers/Work/')), isEmpty);
    });

    test('a template folder stays untouched whatever its mark', () async {
      files.addFile('Documents/Car/insurance.pdf', text: 'already sorted');
      await marks().mark(LogicalPath('Documents'), Zone.chaos);
      expect(
        (await plan()).keys.where((p) => p.startsWith('Documents/')),
        isEmpty,
      );
    });

    test('removing the mark brings the plan back', () async {
      final before = await plan();
      await marks().mark(LogicalPath('Download'), Zone.organized);
      await marks().unmark(LogicalPath('Download'));
      expect(await app.read(zoneMarksProvider.future), isEmpty);
      expect(await plan(), before);
    });
  });

  group('rules', () {
    test('a rule puts files into another template folder', () async {
      expect((await plan())['Download/notes.txt'], 'Documents');
      await rules().save(
        ClassificationRule(
          id: rules().newId(),
          category: Category.archives,
          extensions: const {'txt'},
        ),
      );
      expect((await plan())['Download/notes.txt'], 'Archives');
    });

    test('"leave where it is" keeps matching files in place', () async {
      await rules().save(
        ClassificationRule(
          id: rules().newId(),
          category: Category.unresolved,
          nameContains: 'song',
        ),
      );
      expect((await plan()).keys, isNot(contains('Download/song.mp3')));
      expect(await unresolved(), contains('Download/song.mp3'));
    });

    test('the order decides; moving a rule up changes the plan', () async {
      final toArchives = ClassificationRule(
        id: rules().newId(),
        category: Category.archives,
        extensions: const {'txt'},
      );
      final toOther = ClassificationRule(
        id: rules().newId(),
        category: Category.other,
        nameContains: 'notes',
      );
      await rules().save(toArchives);
      await rules().save(toOther);
      expect((await plan())['Download/notes.txt'], 'Archives');

      await rules().move(toOther.id, up: true);
      final ordered = await app.read(userRulesProvider.future);
      expect([for (final r in ordered) r.id], [toOther.id, toArchives.id]);
      expect([for (final r in ordered) r.priority], [0, 10]);
      expect((await plan())['Download/notes.txt'], 'Other');

      await rules().remove(toOther.id);
      expect((await plan())['Download/notes.txt'], 'Archives');
    });

    test('changing a rule keeps its place', () async {
      final first = ClassificationRule(
        id: rules().newId(),
        category: Category.archives,
        extensions: const {'txt'},
      );
      final second = ClassificationRule(
        id: rules().newId(),
        category: Category.other,
        extensions: const {'mp3'},
      );
      await rules().save(first);
      await rules().save(second);
      await rules().save(
        ClassificationRule(
          id: first.id,
          category: Category.music,
          extensions: const {'txt'},
        ),
      );
      final ordered = await app.read(userRulesProvider.future);
      expect([for (final r in ordered) r.id], [first.id, second.id]);
      expect(ordered.first.category, Category.music);
    });
  });

  group('quarantine retention', () {
    Future<void> cleanUpAndWait(Duration retention, Duration later) async {
      await app
          .read(settingsProvider.notifier)
          .setQuarantineRetention(retention);
      await workflow().start();
      await workflow().execute();
      workflow().dismiss();
      device.clock.advance(later);
      await launch();
    }

    Future<bool> purged() async {
      final session = (await app.read(historyProvider.future)).single;
      final detail = await app.read(sessionDetailProvider(session.id).future);
      return detail!.purged > 0;
    }

    test(
      '7 days: copies older than that are purged on the next start',
      () async {
        await cleanUpAndWait(const Duration(days: 7), const Duration(days: 8));
        expect(await purged(), isTrue);
      },
    );

    test('30 days: the same copies are kept', () async {
      await cleanUpAndWait(const Duration(days: 30), const Duration(days: 8));
      expect(await purged(), isFalse);
    });

    test('the choices', () {
      expect(quarantineRetentions.map((d) => d.inDays), [7, 14, 30, 60, 90]);
    });
  });

  group('language', () {
    test(
      'chosen in the settings: saved, and the texts follow at once',
      () async {
        expect(app.read(appTextsProvider).scanning, 'Looking at your files');
        await app.read(settingsProvider.notifier).setUiLocale('ru');
        expect(app.read(appTextsProvider).scanning, 'Просматриваю файлы');
        expect((await app.read(settingsProvider.future)).uiLocale, 'ru');

        await launch();
        expect(app.read(uiLocaleProvider), 'ru');

        await app.read(settingsProvider.notifier).setUiLocale(null);
        expect(app.read(appTextsProvider).scanning, 'Looking at your files');
      },
    );
  });

  test('the folders of the storage, for the picker', () async {
    expect(
      await app.read(childFoldersProvider(LogicalPath.root).future),
      containsAll(['Download', 'Papers']),
    );
    expect(await app.read(childFoldersProvider(LogicalPath('Papers')).future), [
      'Car',
      'Home',
      'Taxes',
      'Work',
    ]);
  });
}
