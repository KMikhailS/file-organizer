import 'dart:async';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/foreground_binding.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/texts/localized_app_texts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';
import '../support/fs/in_memory_file_source.dart';
import '../support/scenarios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('noticeFor', () {
    const source = SourceId('s');
    const scanning = Scanning(
      sourceId: source,
      sourceIndex: 0,
      sourceCount: 1,
      filesProcessed: 125,
    );
    const analyzing = Analyzing(
      sourceId: source,
      sourceIndex: 0,
      sourceCount: 1,
      sizesDone: 3,
      sizesTotal: 7,
    );

    test('working states show progress, the others stop the service', () {
      final en = LocalizedAppTexts.forLanguages(const ['en']);
      final notice = ForegroundBinding.noticeFor(scanning, en)!;
      expect(
        (notice.title, notice.text, notice.done, notice.total),
        ('Looking at your files', '125 files', 0, 0),
      );
      expect(notice.channelName, 'Cleanup progress');

      final step = ForegroundBinding.noticeFor(analyzing, en)!;
      expect((step.title, step.text), ('Looking for duplicates', '3 of 7'));
      expect((step.done, step.total), (3, 7));

      expect(ForegroundBinding.noticeFor(const Idle(), en), isNull);
      expect(ForegroundBinding.noticeFor(const Failed('x'), en), isNull);
    });

    test('in Russian, with Russian plurals', () {
      final ru = LocalizedAppTexts.forLanguages(const ['ru-RU']);
      final notice = ForegroundBinding.noticeFor(scanning, ru)!;
      expect((notice.title, notice.text), ('Просматриваю файлы', '125 файлов'));
      expect(notice.channelName, 'Ход уборки');
      expect(ForegroundBinding.noticeFor(analyzing, ru)!.text, '3 из 7');
      expect(
        [
          for (final n in [1, 2, 5, 21, 22, 111]) ru.filesSeen(n),
        ],
        ['1 файл', '2 файла', '5 файлов', '21 файл', '22 файла', '111 файлов'],
      );
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
      container = ProviderContainer(overrides: device.overrides);
      addTearDown(container.dispose);
      await device.fixFolderNames();
      await container.read(appControllerProvider.notifier).start();
    });

    CleanupWorkflow workflow() => container.read(workflowProvider);

    test('runs while planning and stops at the plan', () async {
      await workflow().start();
      await pumpEventQueue();
      expect(workflow().state, isA<PlanReady>());
      final calls = device.foreground.calls;
      expect(calls.first, 'start Looking at your files');
      expect(calls, contains('update Looking for duplicates'));
      expect(calls.last, 'stop');
      expect(calls.where((c) => c.startsWith('start')), hasLength(1));
    });

    test('the notification follows a change of language at once', () async {
      var switched = false;
      files.onHashBlock = (_, _) {
        if (!switched) {
          switched = true;
          // The user switches the phone to Russian while it works.
          container.read(systemLanguagesProvider.notifier).changed(const [
            'ru-RU',
          ]);
        }
      };
      await workflow().start();
      await pumpEventQueue();
      expect(switched, isTrue);
      final calls = device.foreground.calls;
      expect(calls.first, 'start Looking at your files');
      expect(calls, contains('update Ищу дубли'));
      expect(calls.last, 'stop');
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
