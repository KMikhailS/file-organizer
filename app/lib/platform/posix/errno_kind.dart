import 'dart:io';

import 'package:file_organizer/core/model/file_error_kind.dart';

/// Which family of POSIX systems the adapter runs on. Most `errno` numbers
/// are the same in both; a few, such as `ENOTEMPTY`, are not.
enum PosixFlavor {
  /// Linux and Android (glibc, bionic).
  linux,

  /// macOS and iOS.
  darwin;

  /// The flavor of the running system.
  static PosixFlavor get current =>
      Platform.isMacOS || Platform.isIOS ? darwin : linux;
}

/// `errno` numbers the adapter tells apart. All but `ENOTEMPTY` are the
/// same on Linux, Android and macOS.
abstract final class Errno {
  static const int perm = 1;
  static const int noEnt = 2;
  static const int acces = 13;
  static const int busy = 16;
  static const int exist = 17;
  static const int xDev = 18;
  static const int notDir = 20;
  static const int isDir = 21;
  static const int txtBsy = 26;
  static const int roFs = 30;

  // Linux and Android only: the answers of `renameat2` when the file
  // system does not support its flags.
  static const int inval = 22;
  static const int noSys = 38;
  static const int opNotSupp = 95;

  /// `ENOTEMPTY`: 39 on Linux and Android, 66 on macOS.
  static int notEmpty(PosixFlavor flavor) => switch (flavor) {
    PosixFlavor.linux => 39,
    PosixFlavor.darwin => 66,
  };
}

/// What a failed system call with [errno] means for the core
/// (`docs/stage2_android.md`, section 5.1).
///
/// `EXDEV` (another volume) is an [FileErrorKind.ioError]: a move never
/// leaves its volume. `EISDIR` is a [FileErrorKind.wrongType] like
/// `ENOTDIR`: a file was expected and a folder was found.
FileErrorKind fileErrorKindOf(int errno, PosixFlavor flavor) {
  if (errno == Errno.notEmpty(flavor)) {
    return FileErrorKind.notEmpty;
  }
  return switch (errno) {
    Errno.noEnt => FileErrorKind.notFound,
    Errno.notDir || Errno.isDir => FileErrorKind.wrongType,
    Errno.acces || Errno.perm || Errno.roFs => FileErrorKind.permissionDenied,
    Errno.exist => FileErrorKind.targetExists,
    Errno.busy || Errno.txtBsy => FileErrorKind.locked,
    _ => FileErrorKind.ioError,
  };
}
