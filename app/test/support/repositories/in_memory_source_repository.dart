import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemorySourceRepository implements SourceRepository {
  final Map<SourceId, Source> _sources = {};

  @override
  Future<List<Source>> all() async =>
      _sources.values.toList()
        ..sort((a, b) => a.id.value.compareTo(b.id.value));

  @override
  Future<Source?> byId(SourceId id) async => _sources[id];

  @override
  Future<void> save(Source source) async => _sources[source.id] = source;
}
