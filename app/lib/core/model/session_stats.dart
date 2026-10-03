import 'package:file_organizer/core/model/operation.dart';
import 'package:file_organizer/core/model/operation_status.dart';
import 'package:meta/meta.dart';

/// Summary of a cleanup session, for the result and history screens.
@immutable
final class SessionStats {
  /// Throws [ArgumentError] if a count is negative or the status counts add
  /// up to more than [total].
  SessionStats({
    required this.total,
    required this.done,
    required this.failed,
    required this.skipped,
    required this.reverted,
    required this.revertSkipped,
    required this.removedBytes,
  }) {
    for (final (name, value) in [
      ('total', total),
      ('done', done),
      ('failed', failed),
      ('skipped', skipped),
      ('reverted', reverted),
      ('revertSkipped', revertSkipped),
      ('removedBytes', removedBytes),
    ]) {
      RangeError.checkNotNegative(value, name);
    }
    if (done + failed + skipped + reverted + revertSkipped > total) {
      throw ArgumentError('status counts exceed total $total');
    }
  }

  /// Counts [operations] by status. [removedBytes] is the size of the files
  /// currently out of the way: done or revertSkipped quarantine and
  /// addToAlbum operations.
  factory SessionStats.of(Iterable<Operation> operations) {
    var total = 0;
    final counts = {for (final s in OperationStatus.values) s: 0};
    var bytes = 0;
    for (final operation in operations) {
      total++;
      counts[operation.status] = counts[operation.status]! + 1;
      final stillRemoved =
          operation.status == OperationStatus.done ||
          operation.status == OperationStatus.revertSkipped;
      if (stillRemoved && operation.type.removesFile) {
        bytes += operation.fingerprint!.size;
      }
    }
    return SessionStats(
      total: total,
      done: counts[OperationStatus.done]!,
      failed: counts[OperationStatus.failed]!,
      skipped: counts[OperationStatus.skipped]!,
      reverted: counts[OperationStatus.reverted]!,
      revertSkipped: counts[OperationStatus.revertSkipped]!,
      removedBytes: bytes,
    );
  }

  static final SessionStats empty = SessionStats(
    total: 0,
    done: 0,
    failed: 0,
    skipped: 0,
    reverted: 0,
    revertSkipped: 0,
    removedBytes: 0,
  );

  /// All operations of the session.
  final int total;

  final int done;

  final int failed;

  final int skipped;

  final int reverted;

  final int revertSkipped;

  /// Bytes of files currently out of the way (quarantined or album-marked).
  final int removedBytes;

  /// Operations still pending.
  int get pending => total - done - failed - skipped - reverted - revertSkipped;

  @override
  bool operator ==(Object other) =>
      other is SessionStats &&
      other.total == total &&
      other.done == done &&
      other.failed == failed &&
      other.skipped == skipped &&
      other.reverted == reverted &&
      other.revertSkipped == revertSkipped &&
      other.removedBytes == removedBytes;

  @override
  int get hashCode => Object.hash(
    total,
    done,
    failed,
    skipped,
    reverted,
    revertSkipped,
    removedBytes,
  );

  @override
  String toString() =>
      'SessionStats(total: $total, done: $done, failed: $failed, '
      'skipped: $skipped, reverted: $reverted, '
      'revertSkipped: $revertSkipped, removedBytes: $removedBytes)';
}
