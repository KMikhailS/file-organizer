import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/platform/android/native_api.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Dart wrapper of the native layer on the host, with fake APIs. The
/// native side itself is tested on emulators (integration_test/native/).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStorage storage;
  late _FakeAccess access;
  late AndroidNative native;

  setUp(() {
    storage = _FakeStorage();
    access = _FakeAccess();
    native = AndroidNative(access: access, storage: storage);
  });

  test('capture dates come back as UTC times', () async {
    storage.dates = {'/s/a.jpg': 1620284889000};
    final result = await native.capturedDates(['/s/a.jpg', '/s/b.txt']);
    expect((result as NativeOk<Map<String, DateTime>>).value, {
      '/s/a.jpg': DateTime.utc(2021, 5, 6, 7, 8, 9),
    });
    expect(storage.asked, [
      ['/s/a.jpg', '/s/b.txt'],
    ]);
  });

  test('no paths, no native call', () async {
    final result = await native.capturedDates(const []);
    expect((result as NativeOk<Map<String, DateTime>>).value, isEmpty);
    expect(storage.asked, isEmpty);
  });

  test('native errors become failures, never exceptions', () async {
    access.error = PlatformException(code: 'no-activity', message: 'gone');
    expect(
      await native.requestAllFilesAccess(),
      const NativeFailed<bool>('no-activity', 'gone'),
    );
    expect(
      await native.hasNotificationPermission(),
      const NativeFailed<bool>('no-activity', 'gone'),
    );
  });

  test('answers pass through', () async {
    access.answer = true;
    expect(await native.hasAllFilesAccess(), const NativeOk(true));
    expect(
      await native.primaryStorageRoot(),
      const NativeOk<String?>('/storage/emulated/0'),
    );
  });

  test('time limit events reach the listeners', () async {
    final events = <void>[];
    final subscription = native.foregroundTimeouts.listen(events.add);
    await native.onTimeout();
    await native.onTimeout();
    await pumpEventQueue();
    expect(events, hasLength(2));
    await subscription.cancel();
  });
}

final class _FakeAccess implements AccessApi {
  bool answer = false;
  PlatformException? error;

  Future<bool> _answer() async {
    if (error case final e?) {
      throw e;
    }
    return answer;
  }

  @override
  Future<bool> hasAllFilesAccess() => _answer();

  @override
  Future<bool> requestAllFilesAccess() => _answer();

  @override
  Future<bool> hasNotificationPermission() => _answer();

  @override
  Future<bool> requestNotificationPermission() => _answer();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeStorage implements StorageApi {
  Map<String, int> dates = {};
  final List<List<String>> asked = [];

  @override
  Future<Map<String, int>> capturedDates(List<String> paths) async {
    asked.add(paths);
    return {
      for (final path in paths)
        if (dates.containsKey(path)) path: dates[path]!,
    };
  }

  @override
  Future<String?> primaryStorageRoot() async => '/storage/emulated/0';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
