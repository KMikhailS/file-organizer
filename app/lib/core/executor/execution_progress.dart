import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation.dart';
import 'package:meta/meta.dart';

/// Progress of an execution, sent after each operation.
@immutable
final class ExecutionProgress {
  const ExecutionProgress({
    required this.sessionId,
    required this.total,
    required this.done,
    required this.skipped,
    required this.failed,
    required this.last,
  });

  final SessionId sessionId;

  /// Approved operations of the plan.
  final int total;

  final int done;

  final int skipped;

  final int failed;

  /// The operation just finished, as journaled.
  final Operation last;

  /// Operations processed so far.
  int get processed => done + skipped + failed;

  @override
  bool operator ==(Object other) =>
      other is ExecutionProgress &&
      other.sessionId == sessionId &&
      other.total == total &&
      other.done == done &&
      other.skipped == skipped &&
      other.failed == failed &&
      other.last == last;

  @override
  int get hashCode =>
      Object.hash(sessionId, total, done, skipped, failed, last);

  @override
  String toString() =>
      'ExecutionProgress($processed/$total: done $done, skipped $skipped, '
      'failed $failed)';
}
