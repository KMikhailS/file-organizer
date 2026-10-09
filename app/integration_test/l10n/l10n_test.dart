// The language of the device reaches the app (docs/stage2_android.md,
// 5.15). Run it with run_android.sh, never on its own: the script sets the
// language, passes it as EXPECT_LANGUAGE and, while the test prints
// L10N|SHOWN, reads the notification from the system.
import 'dart:ui' show PlatformDispatcher;

import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/foreground_binding.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/localization.dart';
import 'package:file_organizer/ui/texts/localized_app_texts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/support/folder_names.dart';

const String expected = String.fromEnvironment('EXPECT_LANGUAGE');

void say(String what) {
  // ignore: avoid_print, the protocol with run_android.sh is the output.
  print('L10N|$what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('the app speaks the language of the device', () async {
    expect(expected, anyOf('en', 'ru'), reason: 'pass EXPECT_LANGUAGE');
    final services = AppServices.android();
    final container = ProviderContainer(
      overrides: [
        appServicesProvider.overrideWithValue(services),
        ...localizationOverrides(),
      ],
    );
    addTearDown(container.dispose);

    final system = PlatformDispatcher.instance.locales;
    say('SYSTEM ${tagsOf(system).join(',')}');
    expect(
      resolveLanguage(container.read(languagesProvider)).languageCode,
      expected,
    );

    // A clean install: the first start asks for the folder names.
    final app = container.read(appControllerProvider.notifier);
    await app.start();
    expect(container.read(appControllerProvider), const FolderNamesNeeded());
    final proposal = container.read(proposedFolderNamesProvider);
    expect(proposal, expected == 'ru' ? russianNames : englishNames);
    await app.confirmFolderNames(proposal);
    expect(container.read(appControllerProvider), isA<AppReady>());
    say('FOLDERS ${proposal.values.join(',')}');

    // The notification as the service binding builds it, on the real
    // service.
    final notice = ForegroundBinding.noticeFor(
      const Scanning(
        sourceId: AppController.storageId,
        sourceIndex: 0,
        sourceCount: 1,
        filesProcessed: 125,
      ),
      container.read(appTextsProvider),
    )!;
    expect(
      await services.native.startForeground(notice),
      isA<NativeOk<void>>(),
    );
    // The service starts asynchronously.
    String? title;
    for (var i = 0; i < 50 && title != notice.title; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final shown = await services.native.currentForegroundNotice();
      title = shown is NativeOk<ForegroundNotice?> ? shown.value?.title : null;
    }
    expect(title, notice.title);
    say('SHOWN');
    // The script reads the notification meanwhile.
    await Future<void>.delayed(const Duration(seconds: 8));
    await services.native.stopForeground();
    say('DONE');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
