import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';
import '../support/folder_names.dart';
import '../support/fs/in_memory_file_source.dart';
import '../support/scenarios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevice device;
  late ProviderContainer container;

  setUp(() {
    device = FakeDevice();
    container = ProviderContainer(overrides: device.overrides);
    addTearDown(container.dispose);
  });

  AppController controller() => container.read(appControllerProvider.notifier);
  AppStatus status() => container.read(appControllerProvider);
  Future<List<Source>> sources() =>
      DriftSourceRepository(device.database).all();

  group('after the first start', () {
    setUp(() => device.fixFolderNames());

    test('without access: nothing is opened or recovered', () async {
      await controller().start();
      expect(status(), const AccessNeeded());
      expect(device.opened, isEmpty);
      expect(await sources(), isEmpty);
      expect(device.foreground.calls, isEmpty);
    });

    test(
      'with access: the storage source is created, opened and kept',
      () async {
        device.access.allFiles = true;
        await controller().start();
        expect(status(), const AppReady(desktopCapabilities));
        final saved = (await sources()).single;
        expect(saved.id, AppController.storageId);
        expect(saved.kind, SourceKind.androidFullStorage);
        expect(saved.location, '/storage/emulated/0');
        expect(saved.capabilities, desktopCapabilities);
        expect(
          container.read(openSourcesProvider).lookup(AppController.storageId),
          isNotNull,
        );
      },
    );

    test('a second start does nothing once ready', () async {
      device.access.allFiles = true;
      await Future.wait([controller().start(), controller().start()]);
      await controller().start();
      expect(device.opened, hasLength(1));
      expect(await sources(), hasLength(1));
    });

    test('access granted on the settings screen: then it starts', () async {
      await controller().start();
      expect(status(), const AccessNeeded());
      device.access.grantOnRequest = true;
      await controller().requestAccess();
      expect(device.access.requests, 1);
      expect(status(), isA<AppReady>());
    });

    test('a storage that moved: the source follows', () async {
      // Saved by an earlier run, when the storage had another path.
      await DriftSourceRepository(device.database).save(
        const Source(
          id: AppController.storageId,
          kind: SourceKind.androidFullStorage,
          displayName: 'Internal storage',
          location: '/storage/emulated/10',
          capabilities: SourceCapabilities.none,
          enabled: true,
        ),
      );
      device.access.allFiles = true;
      await controller().start();
      expect((await sources()).single.location, '/storage/emulated/0');
      expect(device.opened.single.location, '/storage/emulated/0');
    });

    test('no mounted storage: the start fails', () async {
      device.access.allFiles = true;
      device.storage.root = null;
      await controller().start();
      expect(status(), isA<StartupFailed>());
    });

    test('the start recovers interrupted sessions', () async {
      final session = CleanupSession(
        id: const SessionId('crashed'),
        startedAt: DateTime.utc(2024),
        status: SessionStatus.planned,
        stats: SessionStats.empty,
      );
      final sessions = DriftSessionRepository(device.database);
      await sessions.save(session);
      await sessions.save(session.transitionTo(SessionStatus.running));

      device.access.allFiles = true;
      await controller().start();
      expect(container.read(workflowProvider).state, isA<Interrupted>());
      expect(
        (await sessions.byId(const SessionId('crashed')))!.status,
        SessionStatus.failed,
      );
    });
  });

  group('the first start: the folder names', () {
    Future<Settings> settings() =>
        DriftSettingsRepository(device.database).load();

    test('after the access, the names are proposed in the language of the '
        'system; the workflow waits for them', () async {
      device.languages = const ['ru-RU', 'en-US'];
      await controller().start();
      expect(status(), const AccessNeeded());

      device.access.allFiles = true;
      await controller().start();
      expect(status(), const FolderNamesNeeded());
      expect(container.read(proposedFolderNamesProvider), russianNames);
      expect((await settings()).layoutFolderNames, isNull);
      expect(container.read(layoutFolderNamesProvider), isNull);
      expect(
        () => container.read(workflowProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isStateError,
          ),
        ),
      );
      expect(device.foreground.calls, isEmpty);
    });

    test('confirmed names are saved and the start goes on; the plan uses '
        'them', () async {
      device.languages = const ['ru'];
      device.access.allFiles = true;
      await controller().start();
      await controller().confirmFolderNames(
        container.read(proposedFolderNamesProvider),
      );
      expect(status(), const AppReady(desktopCapabilities));
      expect((await settings()).layoutFolderNames, russianNames);

      final workflow = container.read(workflowProvider);
      await workflow.start();
      final plan = (workflow.state as PlanReady).plans.single.plan;
      final targets = {
        for (final op in plan.operations)
          if (op.toPath case final to?) to.segments.first,
      };
      expect(targets, contains('Документы'));
      expect(targets, isNot(contains('Documents')));
    });

    test('the names are asked once; another language later does not change '
        'them', () async {
      device.languages = const ['ru'];
      device.access.allFiles = true;
      await controller().start();
      await controller().confirmFolderNames(russianNames);

      // The next run of the app, the phone now in English.
      device.languages = const ['en'];
      final next = ProviderContainer(overrides: device.overrides);
      addTearDown(next.dispose);
      await next.read(appControllerProvider.notifier).start();
      expect(next.read(appControllerProvider), isA<AppReady>());
      expect(next.read(layoutFolderNamesProvider), russianNames);
      expect((await settings()).layoutFolderNames, russianNames);
    });

    test(
      'names that break the template are refused; nothing is saved',
      () async {
        device.access.allFiles = true;
        await controller().start();
        final proposal = container.read(proposedFolderNamesProvider);
        for (final broken in [
          {...proposal, Category.photos: 'Pictures/Camera'},
          {...proposal, Category.photos: proposal[Category.videos]!},
          {...proposal, Category.photos: '.photos'},
          {...proposal}..remove(Category.music),
        ]) {
          await expectLater(
            controller().confirmFolderNames(broken),
            throwsArgumentError,
          );
        }
        expect(status(), const FolderNamesNeeded());
        expect((await settings()).layoutFolderNames, isNull);
      },
    );

    test('a confirmation out of turn is a mistake', () async {
      await expectLater(
        controller().confirmFolderNames(englishNames),
        throwsStateError,
      );
      device.access.allFiles = true;
      await controller().start();
      await controller().confirmFolderNames(englishNames);
      await expectLater(
        controller().confirmFolderNames(russianNames),
        throwsStateError,
      );
      expect((await settings()).layoutFolderNames, englishNames);
      expect(container.read(layoutFolderNamesProvider), englishNames);
    });

    test(
      'two confirmations at once: the second fails, the first is kept',
      () async {
        device.access.allFiles = true;
        await controller().start();
        final first = controller().confirmFolderNames(englishNames);
        final second = expectLater(
          controller().confirmFolderNames(russianNames),
          throwsStateError,
        );
        await first;
        await second;
        expect(status(), isA<AppReady>());
        expect((await settings()).layoutFolderNames, englishNames);
        expect(container.read(layoutFolderNamesProvider), englishNames);
      },
    );

    test('fixed names cannot be replaced while the app runs', () async {
      device.access.allFiles = true;
      await controller().start();
      await controller().confirmFolderNames(englishNames);
      final names = container.read(layoutFolderNamesProvider.notifier);
      expect(() => names.fix(russianNames), throwsStateError);
      names.fix(englishNames);
      expect(container.read(layoutFolderNamesProvider), englishNames);
    });
  });

  group('the folder names before the access', () {
    test('saved names are known even without access (access taken back '
        'later, not a first start)', () async {
      await device.fixFolderNames();
      await controller().start();
      expect(status(), const AccessNeeded());
      expect(container.read(layoutFolderNamesProvider), englishNames);
    });

    test('a first start without access knows no names', () async {
      await controller().start();
      expect(status(), const AccessNeeded());
      expect(container.read(layoutFolderNamesProvider), isNull);
    });

    test('while confirmed names are saved the status says so', () async {
      device.access.allFiles = true;
      await controller().start();
      final seen = <AppStatus>[];
      final subscription = container.listen(
        appControllerProvider,
        (_, next) => seen.add(next),
      );
      addTearDown(subscription.close);
      await controller().confirmFolderNames(englishNames);
      expect(seen.first, const FolderNamesNeeded(saving: true));
      expect(seen.last, isA<AppReady>());
    });
  });

  group('the language', () {
    test('the one chosen in the settings comes before the system\'s', () async {
      await DriftSettingsRepository(device.database)
          .save(Settings(uiLocale: 'ru'));
      await controller().start();
      expect(container.read(uiLocaleProvider), 'ru');
      expect(container.read(appTextsProvider).restoredLabel, 'восстановлено');
      expect(container.read(proposedFolderNamesProvider), russianNames);
    });

    test('undo names a file brought back next to a taken name in the '
        'language of the start', () async {
      late InMemoryFileSource files;
      final phone = FakeDevice(
        files: (source) =>
            files = InMemoryFileSource(sourceId: source.id)
              ..withTypicalDownloadFolder(),
      )..languages = const ['ru'];
      phone.access.allFiles = true;
      await phone.fixFolderNames();
      final app = ProviderContainer(overrides: phone.overrides);
      addTearDown(app.dispose);
      await app.read(appControllerProvider.notifier).start();

      final workflow = app.read(workflowProvider);
      await workflow.start();
      await workflow.execute();
      expect(workflow.state, isA<Completed>());
      expect(files.isFile('Download/notes.txt'), isFalse);
      // The phone switches to English: the running workflow keeps its label.
      app.read(systemLanguagesProvider.notifier).changed(const ['en']);
      expect(app.read(appTextsProvider).restoredLabel, 'restored');
      expect(app.read(workflowProvider), same(workflow));
      files.addFile('Download/notes.txt', text: 'a new file, same name');

      await workflow.undo();
      expect(files.isFile('Download/notes (восстановлено).txt'), isTrue);
      expect(files.readText('Download/notes.txt'), 'a new file, same name');
    });
  });
}
