import 'package:file_organizer/core/ports/id_generator.dart';

/// Predictable ids: `id-1`, `id-2`, ...
class SequentialIdGenerator implements IdGenerator {
  SequentialIdGenerator([this.prefix = 'id']);

  final String prefix;

  int _next = 1;

  @override
  String newId() => '$prefix-${_next++}';
}
