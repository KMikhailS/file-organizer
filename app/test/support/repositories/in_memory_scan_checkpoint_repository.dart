import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemoryScanCheckpointRepository implements ScanCheckpointRepository {
  final Map<SourceId, ScanCheckpoint> _checkpoints = {};

  @override
  Future<ScanCheckpoint?> bySource(SourceId sourceId) async =>
      _checkpoints[sourceId];

  @override
  Future<void> save(ScanCheckpoint checkpoint) async =>
      _checkpoints[checkpoint.sourceId] = checkpoint;

  @override
  Future<void> clear(SourceId sourceId) async => _checkpoints.remove(sourceId);
}
