import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/platform/android/native_api.g.dart';
import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/texts/localized_app_texts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_clock.dart';
import 'fs/in_memory_file_source.dart';
import 'scenarios.dart';
import 'sequential_id_generator.dart';

/// "All files access", the notification permission and the storage root of
/// a fake device.
final class FakeAccess implements AccessApi {
  bool allFiles = false;

  /// What the user does on the settings screen.
  bool grantOnRequest = false;
  int requests = 0;

  @override
  Future<bool> hasAllFilesAccess() async => allFiles;

  @override
  Future<bool> requestAllFilesAccess() async {
    requests++;
    if (grantOnRequest) {
      allFiles = true;
    }
    return allFiles;
  }

  /// The notification permission (always granted below Android 13).
  bool notifications = true;

  /// What the user answers in the system dialog.
  bool allowNotificationsOnRequest = false;
  int notificationRequests = 0;

  /// The native calls about notifications fail (a platform error).
  bool notificationCallsFail = false;

  @override
  Future<bool> hasNotificationPermission() async {
    if (notificationCallsFail) {
      throw PlatformException(code: 'broken');
    }
    return notifications;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    notificationRequests++;
    if (allowNotificationsOnRequest) {
      notifications = true;
    }
    return notifications;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeStorage implements StorageApi {
  String? root = '/storage/emulated/0';

  @override
  Future<String?> primaryStorageRoot() async => root;

  @override
  Future<Map<String, int>> capturedDates(List<String> paths) async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The foreground service: records every call.
final class FakeForeground implements ForegroundApi {
  final List<String> calls = [];
  ForegroundNotice? shown;

  @override
  Future<void> start(ForegroundNotice notice) async {
    calls.add('start ${notice.title}');
    shown = notice;
  }

  @override
  Future<void> update(ForegroundNotice notice) async {
    calls.add('update ${notice.title}');
    shown = notice;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    shown = null;
  }

  @override
  Future<bool> isRunning() async => shown != null;

  @override
  Future<ForegroundNotice?> currentNotice() async => shown;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake device for the state layer: native APIs, an in-memory database
/// and in-memory file sources.
final class FakeDevice {
  /// With [restartable], the database is a file in a temporary folder
  /// (removed after the test): each start of the app opens it anew, so a
  /// test can close the app and start it again on the same data.
  FakeDevice({this._files, this.restartable = false});

  final bool restartable;

  final FakeAccess access = FakeAccess();
  final FakeStorage storage = FakeStorage();
  final FakeForeground foreground = FakeForeground();
  final FakeClock clock = FakeClock(autoAdvance: const Duration(seconds: 1));

  /// The files of each source; by default a typical Download folder.
  final InMemoryFileSource Function(Source source)? _files;

  /// Thumbnails the fake system has, by logical path.
  final Map<String, Uint8List> thumbnails = {};

  /// Thumbnails asked for, by logical path.
  final List<String> thumbnailRequests = [];

  /// Sources opened so far.
  final List<Source> opened = [];
  late final AndroidNative native = AndroidNative(
    access: access,
    storage: storage,
    foreground: foreground,
  );
  late final String _databasePath = () {
    final folder = Directory.systemTemp.createTempSync('fo_device_');
    addTearDown(() => folder.deleteSync(recursive: true));
    return '${folder.path}/app.sqlite';
  }();

  /// The database of the device, for a test to read and prepare.
  late final AppDatabase database = _open();

  AppDatabase _open() {
    if (!restartable) {
      return AppDatabase(NativeDatabase.memory());
    }
    // Several connections to one file, on purpose (one per start of the
    // app, one for the test): not the mistake drift warns about.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return AppDatabase(NativeDatabase(File(_databasePath)));
  }

  /// The languages of the system, most preferred first.
  List<String> languages = const ['en'];

  /// The overrides of a `ProviderScope` or `ProviderContainer` on this
  /// device, with the app's own localization.
  List<Override> get overrides => [
    appServicesProvider.overrideWithValue(services),
    appTextsFactoryProvider.overrideWithValue(LocalizedAppTexts.forLanguages),
    systemLanguagesProvider.overrideWith(() => SystemLanguages(languages)),
  ];

  /// As if an earlier start fixed the folder names (English by default).
  Future<void> fixFolderNames([Map<Category, String>? names]) async {
    final settings = DriftSettingsRepository(database);
    await settings.save(
      (await settings.load()).copyWith(
        layoutFolderNames:
            names ?? LocalizedAppTexts.forLanguages(const ['en']).folderNames,
      ),
    );
  }

  late final AppServices services = AppServices(
    native: native,
    clock: clock,
    ids: SequentialIdGenerator('dev'),
    // A restartable device gives each start its own connection: the app
    // closes its database when it stops.
    openDatabase: () => restartable ? _open() : database,
    openSource: (source) async {
      opened.add(source);
      return _files?.call(source) ??
          InMemoryFileSource(sourceId: source.id).withTypicalDownloadFolder();
    },
    thumbnail: (source, path, size) async {
      thumbnailRequests.add(path.value);
      return thumbnails[path.value];
    },
  );
}
