import 'dart:io';

import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/platform/posix/errno_kind.dart';
import 'package:file_organizer/platform/posix/libc.dart';
import 'package:file_organizer/platform/posix/no_replace_mover.dart';
import 'package:file_organizer/platform/posix/posix_paths.dart';
import 'package:file_organizer/platform/posix/quarantine_layout.dart';
import 'package:meta/meta.dart';

/// Outcome of [probeMoves]: the mechanism to move files with, or why there
/// is none (the source is then read-only).
typedef ProbeResult = ({MoveMechanism? mechanism, String? problem});

/// Finds out how this source can move files without replacing anything
/// (`docs/stage2_android.md`, decision A.5 and section 5.1), trying it on
/// the adapter's own empty files in `.FileOrganizer/probe/`.
///
/// Creates `.FileOrganizer/` with `.nomedia` on the way. The probe files are
/// never deleted (nothing is, outside the quarantine purge): their names
/// are reused, so they stay a handful of empty files.
///
/// 1. `renameat2(RENAME_NOREPLACE)` onto the own taken file must fail with
///    `EEXIST`; if it moves the file, moves stay off altogether.
/// 2. Onto a free name it must work → [MoveMechanism.renameNoReplace].
/// 3. If the file system rejects the flag (`EINVAL`, `ENOSYS`,
///    `EOPNOTSUPP`), "reserve, then rename" is tried the same way →
///    [MoveMechanism.reserveThenRename].
///
/// [force] picks the mechanism for tests; it must still pass its checks.
/// [renameNoReplace] stands in for `renameat2` in tests, to play file
/// systems that reject the flag or ignore it.
ProbeResult probeMoves({
  required PosixPaths paths,
  required NoReplaceMover Function(MoveMechanism) mover,
  Libc? libc,
  MoveMechanism? force,
  @visibleForTesting int Function(String from, String to)? renameNoReplace,
}) {
  final c = libc ?? Libc.instance;
  final rename = renameNoReplace ?? c.renameNoReplace;
  ProbeResult none(String problem) => (mechanism: null, problem: problem);

  if (!c.canMove) {
    return none('the system has no renameat2 or statx');
  }
  for (final folder in [AppFolder.root, AppFolder.probe]) {
    final problem = _ensureFolder(c, paths.real(folder));
    if (problem != null) {
      return none(problem);
    }
  }
  final a = paths.real(AppFolder.probe.child('a'));
  final b = paths.real(AppFolder.probe.child('b'));
  for (final file in [paths.real(AppFolder.noMedia), a, b]) {
    final problem = _ensureFile(c, file);
    if (problem != null) {
      return none(problem);
    }
  }
  final free = _freeName(c, paths.real(AppFolder.probe));
  if (free == null) {
    return none('no free probe name');
  }

  if (force != MoveMechanism.reserveThenRename) {
    final taken = rename(a, b);
    if (taken == 0) {
      return none('renameat2 with RENAME_NOREPLACE replaced a taken name');
    }
    final unsupported = {Errno.inval, Errno.noSys, Errno.opNotSupp};
    if (taken == Errno.exist) {
      final moved = rename(a, free);
      if (moved == 0) {
        rename(free, a);
        return (mechanism: MoveMechanism.renameNoReplace, problem: null);
      }
      if (!unsupported.contains(moved)) {
        return none('renameat2 failed with errno $moved');
      }
    } else if (!unsupported.contains(taken)) {
      return none('renameat2 failed with errno $taken');
    }
    if (force == MoveMechanism.renameNoReplace) {
      return none('renameat2 with RENAME_NOREPLACE is not supported');
    }
  }

  final fallback = mover(MoveMechanism.reserveThenRename);
  final onTaken = fallback.move(a, b);
  if (onTaken.errorKind != FileErrorKind.targetExists) {
    return none('reserving a taken name gave $onTaken');
  }
  final moved = fallback.move(a, free);
  if (!moved.isSuccess) {
    return none('reserve, then rename failed: $moved');
  }
  fallback.move(free, a);
  return (mechanism: MoveMechanism.reserveThenRename, problem: null);
}

String? _ensureFolder(Libc libc, String path) {
  final errno = libc.mkdir(path);
  if (errno == 0) {
    return null;
  }
  if (errno == Errno.exist &&
      FileSystemEntity.typeSync(path, followLinks: false) ==
          FileSystemEntityType.directory) {
    return null;
  }
  return 'cannot create the folder $path (errno $errno)';
}

String? _ensureFile(Libc libc, String path) {
  final (:created, :errno) = libc.createExclusive(path);
  if (created != null) {
    return null;
  }
  if (errno == Errno.exist && (libc.lstat(path).info?.isRegularFile ?? false)) {
    return null;
  }
  return 'cannot create the file $path (errno $errno)';
}

/// A name in [folder] where nothing is (left over by an interrupted probe,
/// for example), or `null`.
String? _freeName(Libc libc, String folder) {
  for (var i = 0; i < 10; i++) {
    final path = '$folder/c$i';
    if (libc.lstat(path).errno == Errno.noEnt) {
      return path;
    }
  }
  return null;
}
