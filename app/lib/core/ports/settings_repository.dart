import 'package:file_organizer/core/model/settings.dart';

/// Stores the app settings.
abstract interface class SettingsRepository {
  /// The stored settings, or the defaults if none were saved.
  Future<Settings> load();

  Future<void> save(Settings settings);
}
