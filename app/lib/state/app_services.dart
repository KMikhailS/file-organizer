import 'package:drift_flutter/drift_flutter.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/id_generator.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/platform/android/android_file_source.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/platform/services/random_id_generator.dart';
import 'package:file_organizer/platform/services/system_clock.dart';

/// What the app takes from the platform. Tests replace it.
final class AppServices {
  AppServices({
    required this.native,
    required this.clock,
    required this.ids,
    required this.openDatabase,
    required this.openSource,
  });

  /// The Android services: the database file in the app's private storage,
  /// the shared storage through [AndroidFileSource].
  factory AppServices.android() {
    final native = AndroidNative();
    const clock = SystemClock();
    return AppServices(
      native: native,
      clock: clock,
      ids: RandomIdGenerator(),
      openDatabase: () => AppDatabase(driftDatabase(name: 'file_organizer')),
      openSource: (source) => AndroidFileSource.open(
        sourceId: source.id,
        root: source.location,
        clock: clock,
        native: native,
      ),
    );
  }

  final AndroidNative native;
  final Clock clock;
  final IdGenerator ids;

  /// Opens the database; called once per app run.
  final AppDatabase Function() openDatabase;

  /// Opens the files of a source (probing what they allow).
  final Future<FileSource> Function(Source source) openSource;
}
