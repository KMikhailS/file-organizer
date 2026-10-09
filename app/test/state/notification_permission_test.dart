import 'package:file_organizer/state/notification_permission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevice device;
  late ProviderContainer container;

  setUp(() {
    device = FakeDevice();
    container = ProviderContainer(overrides: device.overrides);
    addTearDown(container.dispose);
  });

  Future<bool> granted() =>
      container.read(notificationPermissionProvider.future);
  NotificationPermission permission() =>
      container.read(notificationPermissionProvider.notifier);

  test('granted (Android below 13 always)', () async {
    expect(await granted(), isTrue);
  });

  test('asked: the answer of the user is kept', () async {
    device.access.notifications = false;
    expect(await granted(), isFalse);

    await permission().request();
    expect(device.access.notificationRequests, 1);
    expect(await granted(), isFalse);

    device.access.allowNotificationsOnRequest = true;
    await permission().request();
    expect(await granted(), isTrue);
  });

  test('allowed in the system settings meanwhile: refresh sees it', () async {
    device.access.notifications = false;
    expect(await granted(), isFalse);
    device.access.notifications = true;
    await permission().refresh();
    expect(await granted(), isTrue);
  });

  test('a failing native call counts as not granted', () async {
    device.access.notificationCallsFail = true;
    expect(await granted(), isFalse);
  });
}
