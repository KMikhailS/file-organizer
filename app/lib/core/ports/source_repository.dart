import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/source.dart';

/// Stores sources and their settings.
abstract interface class SourceRepository {
  /// All sources, sorted by id.
  Future<List<Source>> all();

  Future<Source?> byId(SourceId id);

  /// Inserts [source] or replaces the one with the same id.
  Future<void> save(Source source);
}
