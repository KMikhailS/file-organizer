// The Dart <-> Kotlin contract of the Android native layer
// (docs/stage2_android.md, sections 5.2, 5.3 and 5.9).
//
// Callback-style async methods (`@asyncCallback`): the default `suspend`
// functions of Pigeon would need kotlinx-coroutines, a dependency the
// native layer does without.
//
// Regenerate after a change (from app/):
//   dart run pigeon --input pigeons/native_api.dart
//   dart format lib/platform/android/native_api.g.dart
// CI checks that the generated files are up to date.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/android/native_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/app/src/main/kotlin/com/brobrocode/file_organizer/NativeApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.brobrocode.file_organizer'),
    dartPackageName: 'file_organizer',
  ),
)
/// What the progress notification of the foreground service shows. The
/// texts come from the app's localization.
class ForegroundNotice {
  ForegroundNotice({
    required this.title,
    required this.text,
    required this.channelName,
    required this.done,
    required this.total,
  });

  String title;
  String text;

  /// Name of the notification channel in the system settings.
  String channelName;

  /// Progress: [done] of [total]; `total == 0` shows an indeterminate bar.
  int done;
  int total;
}

/// "All files access" and the notification permission. Runs on the main
/// thread: the requests need the activity.
@HostApi()
abstract class AccessApi {
  bool hasAllFilesAccess();

  /// Opens the system screen "All files access" for the app and answers
  /// when the user comes back: whether access is granted then. Answers at
  /// once, without the screen, if access is already granted.
  @asyncCallback
  bool requestAllFilesAccess();

  /// Whether the app may post notifications (Android 13+ runtime
  /// permission, and notifications not turned off for the app).
  bool hasNotificationPermission();

  /// Shows the system dialog (Android 13+) and answers with the result.
  /// Answers at once if the permission is already granted, and on older
  /// versions.
  @asyncCallback
  bool requestNotificationPermission();
}

/// Shared storage. Runs on a background thread.
@HostApi()
abstract class StorageApi {
  /// The root of the primary shared storage (`/storage/emulated/0`), or
  /// `null` if it is not mounted.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String? primaryStorageRoot();

  /// `DATE_TAKEN` of MediaStore, in milliseconds since the epoch (UTC), for
  /// the files at the absolute [paths]. Files without a capture date (not
  /// media, not indexed) are missing from the answer.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Map<String, int> capturedDates(List<String> paths);
}

/// The foreground service (type `dataSync`) that keeps a scan, cleanup or
/// undo running while the app is in the background.
@HostApi()
abstract class ForegroundApi {
  /// Starts the service with its notification, or updates it if it runs.
  void start(ForegroundNotice notice);

  /// Updates the notification. Throttled to a few updates per second; the
  /// last one is always shown.
  void update(ForegroundNotice notice);

  /// Stops the service and removes the notification.
  void stop();

  bool isRunning();

  /// What the notification shows now (read back from the system), or
  /// `null` if there is none.
  ForegroundNotice? currentNotice();
}

/// Calls from the service to Dart.
@FlutterApi()
abstract class ForegroundEvents {
  /// The system stopped the service: the `dataSync` time limit of Android
  /// 15+ ran out. The work in progress should be cancelled.
  @asyncCallback
  void onTimeout();
}
