import 'dart:async';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_texts.dart';
import 'package:file_organizer/state/foreground_binding.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';
import '../support/fs/in_memory_file_source.dart';
import '../support/scenarios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('noticeFor', () {
    test('working states show progress, the others stop the service', () {
      const source = SourceId('s');
      final scanning = ForegroundBinding.noticeFor(
        const Scanning(
          sourceId: source,
          sourceIndex: 0,
          sourceCount: 1,
          filesProcessed: 120,
        ),
      )!;
      expect(
        (scanning.title, scanning.text, scanning.done, scanning.total),
        (AppTexts.scanning, '120 files', 0, 0),
      );
      expect(scanning.channelName, AppTexts.channelName);

      final analyzing = ForegroundBinding.noticeFor(
        const Analyzing(
          sourceId: source,
          sourceIndex: 0,
          sourceCount: 1,
          sizesDone: 3,
          sizesTotal: 7,
        ),
      )!;
      expect((analyzing.done, analyzing.total), (3, 7));

      expect(ForegroundBinding.noticeFor(const Idle()), isNull);
      expect(ForegroundBinding.noticeFor(const Failed('x')), isNull);
    });
  });

  group('following the workflow', () {
    late FakeDevice device;
    late ProviderContainer container;
    late InMemoryFileSource files;

    setUp(() async {
      device = FakeDevice(
        files: (source) =>
            files = InMemoryFileSource(sourceId: source.id)
              ..withPhoneDuplicatePhotos(),
      );
      device.access.allFiles = true;
      container = ProviderContainer(
        overrides: [appServicesProvider.overrideWithValue(device.services)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.notifier).start();
    });

    CleanupWorkflow workflow() => container.read(workflowProvider);

    test('runs while planning and stops at the plan', () async {
      await workflow().start();
      await pumpEventQueue();
      expect(workflow().state, isA<PlanReady>());
      final calls = device.foreground.calls;
      expect(calls.first, 'start ${AppTexts.scanning}');
      expect(calls, contains('update ${AppTexts.analyzing}'));
      expect(calls.last, 'stop');
      expect(calls.where((c) => c.startsWith('start')), hasLength(1));
    });

    test('the time limit of the system cancels the work', () async {
      var timedOut = false;
      files.onHashBlock = (_, _) {
        if (!timedOut) {
          timedOut = true;
          // The service reports its time limit in the middle of hashing.
          unawaited(device.native.onTimeout());
        }
      };
      await workflow().start();
      await pumpEventQueue();
      expect(timedOut, isTrue);
      expect(workflow().state, isA<Idle>());
      expect(device.foreground.calls.last, 'stop');
    });
  });
}
