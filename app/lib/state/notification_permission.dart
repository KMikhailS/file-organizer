import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app may show notifications (Android 13+ asks the user;
/// older versions always allow it). Without it a cleanup still runs, only
/// its progress is not in the notification shade.
final class NotificationPermission extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => _granted(
    ref.read(appServicesProvider).native.hasNotificationPermission(),
  );

  /// Shows the system dialog (if the system still shows it) and keeps the
  /// answer.
  Future<void> request() async {
    state = AsyncData(
      await _granted(
        ref.read(appServicesProvider).native.requestNotificationPermission(),
      ),
    );
  }

  /// Checks again, for example on returning from the system settings.
  Future<void> refresh() async {
    state = AsyncData(await build());
  }

  /// A failed call counts as "not granted": the app then just explains
  /// that the notification may be missing.
  static Future<bool> _granted(Future<NativeResult<bool>> call) async =>
      await call == const NativeOk(true);
}

final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermission, bool>(
      NotificationPermission.new,
    );
