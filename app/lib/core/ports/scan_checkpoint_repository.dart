import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/scan_checkpoint.dart';

/// Where unfinished scans stopped; at most one checkpoint per source.
abstract interface class ScanCheckpointRepository {
  Future<ScanCheckpoint?> bySource(SourceId sourceId);

  /// Inserts [checkpoint] or replaces the one of the same source.
  Future<void> save(ScanCheckpoint checkpoint);

  /// Forgets the checkpoint of a source (the scan finished).
  Future<void> clear(SourceId sourceId);
}
