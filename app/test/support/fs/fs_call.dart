import 'package:file_organizer/core/model/model.dart';

/// Methods of a file source, for fault injection and the call log.
enum FsMethod {
  /// One page of a listing (one call per page).
  list,
  stat,
  exists,
  partialHash,
  fullHash,
  mkdir,
  move,
  quarantine,
  findQuarantined,
  restore,
  removeEmptyDir,
  purgeQuarantined,
  addToAlbum,
  removeFromAlbum;

  /// Methods that change the file system.
  static const Set<FsMethod> mutating = {
    mkdir,
    move,
    quarantine,
    restore,
    removeEmptyDir,
    purgeQuarantined,
    addToAlbum,
    removeFromAlbum,
  };

  bool get isMutating => mutating.contains(this);
}

/// One call to the file source, as recorded in its log.
final class FsCall {
  const FsCall(this.method, {this.path, this.to, this.ref});

  final FsMethod method;

  /// The main path argument, if any (for [FsMethod.move], the source).
  final LogicalPath? path;

  /// The target of a move or restore.
  final LogicalPath? to;

  /// The quarantine reference of a restore or purge.
  final QuarantineRef? ref;

  @override
  String toString() => [
    method.name,
    if (path != null) '$path',
    if (ref != null) '$ref',
    if (to != null) '-> $to',
  ].join(' ');
}

/// Where a simulated crash happens relative to the effect of a call.
enum CrashPoint {
  /// The call does nothing and the process "dies".
  beforeEffect,

  /// The call takes effect, then the process "dies" before the caller sees
  /// the result.
  afterEffect,
}

/// Thrown by the fake file source to simulate the process dying. Production
/// code must not catch it: it extends [Error] like other fatal failures.
final class SimulatedCrash extends Error {
  SimulatedCrash(this.call, this.point);

  final FsCall call;

  final CrashPoint point;

  @override
  String toString() => 'SimulatedCrash(${point.name}: $call)';
}
