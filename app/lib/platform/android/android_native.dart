import 'dart:async';

import 'package:file_organizer/platform/android/native_api.g.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

export 'package:file_organizer/platform/android/native_api.g.dart'
    show ForegroundNotice;

/// Outcome of a call into the Android native layer: a value, or why the
/// call failed. Native calls never throw through this wrapper.
@immutable
sealed class NativeResult<T> {
  const NativeResult();
}

/// A call that worked.
final class NativeOk<T> extends NativeResult<T> {
  const NativeOk(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is NativeOk<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NativeOk($value)';
}

/// A call that failed: [code] is the native error code (`no-activity`,
/// `busy`, `channel-error`, ...).
final class NativeFailed<T> extends NativeResult<T> {
  const NativeFailed(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is NativeFailed<T> &&
      other.code == code &&
      other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'NativeFailed($code: $message)';
}

/// The Android native layer (`pigeons/native_api.dart`,
/// `docs/stage2_android.md`, sections 5.2, 5.3 and 5.9) with typed results:
/// permissions, the storage root, capture dates and the foreground service.
final class AndroidNative implements ForegroundEvents {
  /// The APIs are replaceable for tests; by default they talk to Kotlin.
  AndroidNative({
    AccessApi? access,
    StorageApi? storage,
    ForegroundApi? foreground,
  }) : _access = access ?? AccessApi(),
       _storage = storage ?? StorageApi(),
       _foreground = foreground ?? ForegroundApi();

  final AccessApi _access;
  final StorageApi _storage;
  final ForegroundApi _foreground;
  // This object answers the native calls while someone listens.
  late final StreamController<void> _timeouts = StreamController.broadcast(
    onListen: () => ForegroundEvents.setUp(this),
    onCancel: () => ForegroundEvents.setUp(null),
  );

  // ------------------------------------------------------------ access

  Future<NativeResult<bool>> hasAllFilesAccess() =>
      _call(_access.hasAllFilesAccess);

  /// Opens the system screen and answers when the user comes back.
  Future<NativeResult<bool>> requestAllFilesAccess() =>
      _call(_access.requestAllFilesAccess);

  Future<NativeResult<bool>> hasNotificationPermission() =>
      _call(_access.hasNotificationPermission);

  /// Shows the system dialog (Android 13+) and answers with the result.
  Future<NativeResult<bool>> requestNotificationPermission() =>
      _call(_access.requestNotificationPermission);

  // ----------------------------------------------------------- storage

  /// The root of the primary shared storage, or `null` if it is not
  /// mounted.
  Future<NativeResult<String?>> primaryStorageRoot() =>
      _call(_storage.primaryStorageRoot);

  /// Capture dates (UTC) from MediaStore for the files at the absolute
  /// [paths]; files without one are missing from the map.
  Future<NativeResult<Map<String, DateTime>>> capturedDates(
    Iterable<String> paths,
  ) async {
    final list = paths.toList();
    if (list.isEmpty) {
      return const NativeOk({});
    }
    return switch (await _call(() => _storage.capturedDates(list))) {
      NativeOk(:final value) => NativeOk({
        for (final MapEntry(key: path, value: ms) in value.entries)
          path: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      }),
      NativeFailed(:final code, :final message) => NativeFailed(code, message),
    };
  }

  // -------------------------------------------------------- foreground

  /// Starts the foreground service with [notice], or updates it.
  Future<NativeResult<void>> startForeground(ForegroundNotice notice) =>
      _call(() => _foreground.start(notice));

  /// Updates the notification (throttled natively; the last one shows).
  Future<NativeResult<void>> updateForeground(ForegroundNotice notice) =>
      _call(() => _foreground.update(notice));

  Future<NativeResult<void>> stopForeground() => _call(_foreground.stop);

  Future<NativeResult<bool>> isForegroundRunning() =>
      _call(_foreground.isRunning);

  /// What the notification shows now, read back from the system.
  Future<NativeResult<ForegroundNotice?>> currentForegroundNotice() =>
      _call(_foreground.currentNotice);

  /// An event each time the system stops the service for its time limit
  /// (Android 15+): the running work should be cancelled.
  Stream<void> get foregroundTimeouts => _timeouts.stream;

  /// Called by the native side; use [foregroundTimeouts].
  @override
  @visibleForTesting
  Future<void> onTimeout() async => _timeouts.add(null);

  static Future<NativeResult<T>> _call<T>(Future<T> Function() call) async {
    try {
      return NativeOk(await call());
    } on PlatformException catch (e) {
      return NativeFailed(e.code, e.message);
    }
  }
}
