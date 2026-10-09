import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/last_cleanup.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('none before the first cleanup; the finished one after it, and '
      'again after its undo', () async {
    final device = FakeDevice()..access.allFiles = true;
    await device.fixFolderNames();
    final container = ProviderContainer(overrides: device.overrides);
    addTearDown(container.dispose);
    // Kept alive as the home screen would.
    final subscription = container.listen(lastCleanupProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(appControllerProvider.notifier).start();
    expect(await container.read(lastCleanupProvider.future), isNull);

    final workflow = container.read(workflowProvider);
    await workflow.start();
    // A plan is not a cleanup yet.
    await pumpEventQueue();
    expect(await container.read(lastCleanupProvider.future), isNull);

    await workflow.execute();
    await pumpEventQueue();
    final done = await container.read(lastCleanupProvider.future);
    expect(done?.status, SessionStatus.completed);
    expect(done?.stats.done, greaterThan(0));

    await workflow.undo();
    expect(workflow.state, isA<Reverted>());
    await pumpEventQueue();
    final undone = await container.read(lastCleanupProvider.future);
    expect(undone?.id, done?.id);
    expect(undone?.status, SessionStatus.reverted);
  });
}
