import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemorySettingsRepository implements SettingsRepository {
  Settings? _settings;

  @override
  Future<Settings> load() async => _settings ?? Settings();

  @override
  Future<void> save(Settings settings) async => _settings = settings;
}
