import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/platform/posix/errno_kind.dart';
import 'package:file_organizer/platform/posix/libc.dart';
import 'package:meta/meta.dart';

/// How a file is moved without ever replacing the target
/// (`docs/stage2_android.md`, decision A.5). The capability probe picks it.
enum MoveMechanism {
  /// `renameat2(RENAME_NOREPLACE)`: the kernel refuses a taken target.
  renameNoReplace,

  /// Where the file system does not support the flag (older Android
  /// MediaProvider): take the target name with an empty placeholder
  /// (`O_CREAT | O_EXCL`), check right before the rename that it is still
  /// the same empty file, then rename onto it.
  ///
  /// Residual risk, accepted by the user: another app that opens exactly
  /// this new empty file and writes into it in the fraction of a millisecond
  /// between the check and the rename loses that write. A file that existed
  /// before the reservation can never be replaced.
  reserveThenRename,
}

/// Moves files with a [MoveMechanism]. Paths are real paths; callers check
/// that they lie inside the source.
final class NoReplaceMover {
  NoReplaceMover({
    required this.mechanism,
    required this.setAsideFolder,
    required this.uniqueSuffix,
    Libc? libc,
    PosixFlavor? flavor,
  }) : _libc = libc ?? Libc.instance,
       _flavor = flavor ?? PosixFlavor.current;

  final MoveMechanism mechanism;

  /// Real path of the folder where a placeholder goes when the rename onto
  /// it fails (decision of the user: set aside, never delete). Created on
  /// first use; its parent must exist.
  final String setAsideFolder;

  /// A fresh suffix for the name of a set-aside placeholder.
  final String Function() uniqueSuffix;

  /// For tests: called right after the placeholder at the target is
  /// created, so a test can act as another app in the race window.
  @visibleForTesting
  void Function(String placeholder)? afterReserve;

  final Libc _libc;
  final PosixFlavor _flavor;

  /// Moves [from] to [to]. Fails with `targetExists` if anything is at
  /// [to] (or appears there while moving), `notFound` if [from] or the
  /// folder of [to] is missing. A failed move leaves [from] and [to] as they
  /// were.
  FileResult<void> move(String from, String to) => switch (mechanism) {
    MoveMechanism.renameNoReplace => _result(
      _libc.renameNoReplace(from, to),
      to,
    ),
    MoveMechanism.reserveThenRename => _reserveThenRename(
      from,
      to,
      setAside: true,
    ),
  };

  FileResult<void> _reserveThenRename(
    String from,
    String to, {
    required bool setAside,
  }) {
    final (:reservation, :errno) = _libc.reserve(to);
    if (reservation == null) {
      return _result(errno, to);
    }
    // Kept open until the end, so the identity check cannot be fooled by
    // another file that reuses the inode number.
    try {
      afterReserve?.call(to);
      // Right before the rename: still our empty placeholder?
      if (!_isOwnPlaceholder(to, reservation.identity)) {
        return FileFailure.of(
          FileErrorKind.targetExists,
          '$to was taken over while moving',
        );
      }
      final renamed = _renameOntoOwnPlaceholder(_libc, from, to);
      if (renamed == 0) {
        return succeeded;
      }
      if (setAside) {
        _setAside(to, reservation.identity);
      }
      return _result(renamed, from);
    } finally {
      reservation.release();
    }
  }

  bool _isOwnPlaceholder(String path, FileIdentity placeholder) {
    final (:info, errno: _) = _libc.lstat(path);
    return info != null &&
        info.identity == placeholder &&
        info.isRegularFile &&
        info.size == 0;
  }

  /// Moves the placeholder at [path] out of the way, if it is still ours
  /// and empty. Whatever happens, nothing is deleted or replaced.
  void _setAside(String path, FileIdentity placeholder) {
    if (!_isOwnPlaceholder(path, placeholder)) {
      return;
    }
    final mkdir = _libc.mkdir(setAsideFolder);
    if (mkdir != 0 && mkdir != Errno.exist) {
      return;
    }
    for (var attempt = 0; attempt < 10; attempt++) {
      final target = '$setAsideFolder/${uniqueSuffix()}';
      final moved = _reserveThenRename(path, target, setAside: false);
      if (moved.errorKind != FileErrorKind.targetExists) {
        return;
      }
    }
  }

  /// [errno] of a failed call as a result; [path] is in the message.
  FileResult<void> _result(int errno, String path) {
    if (errno == 0) {
      return succeeded;
    }
    // A path under a file (ENOTDIR) does not exist either.
    final kind = errno == Errno.notDir
        ? FileErrorKind.notFound
        : fileErrorKindOf(errno, _flavor);
    return FileFailure.of(kind, '$path: errno $errno');
  }
}

/// `renameat(from, to)` without any flag: it REPLACES whatever is at [to].
///
/// Called only by [NoReplaceMover] in [MoveMechanism.reserveThenRename],
/// right after checking that [to] is the empty placeholder it has just
/// created. This is the only place where the libc `renameat` may appear
/// (`test/architecture/platform_source_rules.dart`).
int _renameOntoOwnPlaceholder(Libc libc, String from, String to) {
  final renameat = _renameat ??= DynamicLibrary.process()
      .lookupFunction<
        Int32 Function(Int32, Pointer<Utf8>, Int32, Pointer<Utf8>),
        int Function(int, Pointer<Utf8>, int, Pointer<Utf8>)
      >('renameat', isLeaf: true);
  return using((arena) {
    const atFdCwd = -100;
    final rc = renameat(
      atFdCwd,
      from.toNativeUtf8(allocator: arena),
      atFdCwd,
      to.toNativeUtf8(allocator: arena),
    );
    return rc == 0 ? 0 : libc.lastErrno;
  });
}

int Function(int, Pointer<Utf8>, int, Pointer<Utf8>)? _renameat;
