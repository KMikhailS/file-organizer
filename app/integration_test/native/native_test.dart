// The Android native layer on an emulator (docs/stage2_android.md, section
// 5.9). Run it with run_android.sh, never on its own: the script sets the
// permissions up, prepares the MediaStore files, and plays the user on the
// settings screen and in the permission dialog when this test prints
// `NATIVE|<action>`.
//
// The tests run in order and build on each other: access is granted in the
// first group, the capture dates and the notification need it.
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Android API level of the device, from the script.
const int sdk = int.fromEnvironment('SDK_INT');

/// The test folder in shared storage that the script fills and removes.
const String testRoot = '/storage/emulated/0/FileOrganizerTest';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final native = AndroidNative();

  setUpAll(() {
    expect(sdk, greaterThanOrEqualTo(30), reason: 'run via run_android.sh');
  });

  Future<T> ok<T>(Future<NativeResult<T>> call) async => switch (await call) {
    NativeOk(:final value) => value,
    NativeFailed(:final code, :final message) => fail('$code: $message'),
  };

  /// Asks the script to act as the user on the screen that the next call
  /// opens; the script waits for that screen.
  void ask(String action) {
    // ignore: avoid_print, the protocol with run_android.sh is the output.
    print('NATIVE|$action');
  }

  Future<void> eventually(
    Future<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!await condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not met within $timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  ForegroundNotice notice({
    String title = 'Cleaning up',
    String text = 'Starting',
    int done = 0,
    int total = 10,
  }) => ForegroundNotice(
    title: title,
    text: text,
    channelName: 'Cleanup progress',
    done: done,
    total: total,
  );

  group('storage', () {
    test('the primary storage root', () async {
      expect(await ok(native.primaryStorageRoot()), '/storage/emulated/0');
    });
  });

  group('all files access', () {
    test('starts denied', () async {
      expect(await ok(native.hasAllFilesAccess()), isFalse);
    });

    test('the user goes back without granting: false', () async {
      ask('ALL_FILES_BACK');
      expect(await ok(native.requestAllFilesAccess()), isFalse);
      expect(await ok(native.hasAllFilesAccess()), isFalse);
    });

    test('the user grants it on the settings screen: true', () async {
      ask('ALL_FILES_GRANT');
      expect(await ok(native.requestAllFilesAccess()), isTrue);
      expect(await ok(native.hasAllFilesAccess()), isTrue);
    });

    test('once granted, the request answers without the screen', () async {
      expect(
        await ok(native.requestAllFilesAccess())
            .timeout(const Duration(seconds: 3)),
        isTrue,
      );
    });
  });

  group('notifications', () {
    if (sdk >= 33) {
      test('start denied (Android 13+)', () async {
        expect(await ok(native.hasNotificationPermission()), isFalse);
      });

      test('the user denies in the dialog: false', () async {
        ask('NOTIFICATIONS_DENY');
        expect(await ok(native.requestNotificationPermission()), isFalse);
      });

      test('the user allows in the dialog: true', () async {
        ask('NOTIFICATIONS_ALLOW');
        expect(await ok(native.requestNotificationPermission()), isTrue);
        expect(await ok(native.hasNotificationPermission()), isTrue);
      });
    } else {
      test('are allowed without asking before Android 13', () async {
        expect(await ok(native.hasNotificationPermission()), isTrue);
      });
    }

    test('once allowed, the request answers without the dialog', () async {
      expect(
        await ok(native.requestNotificationPermission())
            .timeout(const Duration(seconds: 3)),
        isTrue,
      );
    });
  });

  group('capture dates', () {
    const photo = '$testRoot/dates/photo.jpg';
    // EXIF of the fixture: 2021:05:06 07:08:09, offset +03:00.
    final taken = DateTime.utc(2021, 5, 6, 4, 8, 9);

    test('from the EXIF of an indexed photo', () async {
      expect(await ok(native.capturedDates([photo])), {photo: taken});
    });

    test('no date for other files and for missing paths', () async {
      expect(
        await ok(
          native.capturedDates([
            '$testRoot/dates/plain.txt',
            '$testRoot/dates/missing.jpg',
          ]),
        ),
        isEmpty,
      );
    });

    test('many paths go in several queries', () async {
      final paths = [
        for (var i = 0; i < 1200; i++) '$testRoot/dates/missing-$i.jpg',
        photo,
        photo,
      ];
      expect(await ok(native.capturedDates(paths)), {photo: taken});
    });
  });

  group('foreground service', () {
    Future<ForegroundNotice?> shown() => ok(native.currentForegroundNotice());

    Future<bool> running() => ok(native.isForegroundRunning());

    tearDown(() async {
      await ok(native.stopForeground());
      await eventually(() async => !await running());
    });

    test('starts with its notification and stops', () async {
      expect(await running(), isFalse);
      await ok(native.startForeground(notice()));
      await eventually(running);
      await eventually(() async => await shown() == notice());

      await ok(native.stopForeground());
      await eventually(() async => !await running());
      await eventually(() async => await shown() == null);
    });

    test('shows the last of many fast updates', () async {
      await ok(native.startForeground(notice()));
      await eventually(running);
      for (var i = 1; i <= 50; i++) {
        await ok(
          native.updateForeground(notice(text: 'File $i', done: i, total: 50)),
        );
      }
      await eventually(
        () async =>
            await shown() == notice(text: 'File 50', done: 50, total: 50),
      );
    });

    test('a second start updates the one notification', () async {
      await ok(native.startForeground(notice()));
      await eventually(running);
      await ok(native.startForeground(notice(title: 'Undoing', total: 0)));
      await eventually(
        () async => await shown() == notice(title: 'Undoing', total: 0),
      );
    });

    test('a stop right after the start leaves nothing running', () async {
      await ok(native.startForeground(notice()));
      await ok(native.stopForeground());
      // Give the system time to start and stop the service.
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(await running(), isFalse);
      expect(await shown(), isNull);
      expect(await ok(native.hasAllFilesAccess()), isTrue);
    });

    test('updates without a running service are ignored', () async {
      await ok(native.updateForeground(notice(text: 'late')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(await running(), isFalse);
      expect(await shown(), isNull);
    });
  });
}
