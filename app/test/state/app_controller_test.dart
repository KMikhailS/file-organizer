import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';
import '../support/fs/in_memory_file_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevice device;
  late ProviderContainer container;

  setUp(() {
    device = FakeDevice();
    container = ProviderContainer(
      overrides: [appServicesProvider.overrideWithValue(device.services)],
    );
    addTearDown(container.dispose);
  });

  AppController controller() => container.read(appControllerProvider.notifier);
  AppStatus status() => container.read(appControllerProvider);
  Future<List<Source>> sources() =>
      DriftSourceRepository(device.database).all();

  test('without access: nothing is opened or recovered', () async {
    await controller().start();
    expect(status(), const AccessNeeded());
    expect(device.opened, isEmpty);
    expect(await sources(), isEmpty);
    expect(device.foreground.calls, isEmpty);
  });

  test('with access: the storage source is created, opened and kept', () async {
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
  });

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
}
