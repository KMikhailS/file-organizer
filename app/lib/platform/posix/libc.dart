import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

/// The functions of the system C library that `dart:io` does not offer.
/// Works with glibc (Linux), bionic (Android) and the macOS libc.
///
/// None of them replaces or deletes anything: `renameat2` is only called
/// with `RENAME_NOREPLACE`, `open` only with `O_CREAT | O_EXCL`. The rename
/// onto the adapter's own placeholder and the deletions live next to their
/// checks (`docs/stage2_android.md`, decision A.5 and section 11).
///
/// Every call returns the `errno` of its failure, read right after the call
/// (0 when it worked).
final class Libc {
  Libc._(this._lib)
    : _access = _lib
          .lookupFunction<
            Int32 Function(Pointer<Utf8>, Int32),
            int Function(Pointer<Utf8>, int)
          >('access', isLeaf: true),
      _mkdir = _lib
          .lookupFunction<
            Int32 Function(Pointer<Utf8>, Uint32),
            int Function(Pointer<Utf8>, int)
          >('mkdir', isLeaf: true),
      _open = _lib
          .lookupFunction<
            Int32 Function(Pointer<Utf8>, Int32, VarArgs<(Uint32,)>),
            int Function(Pointer<Utf8>, int, int)
          >('open', isLeaf: true),
      _close = _lib.lookupFunction<Int32 Function(Int32), int Function(int)>(
        'close',
        isLeaf: true,
      ),
      _errno = _lib
          .lookupFunction<Pointer<Int32> Function(), Pointer<Int32> Function()>(
            _errnoSymbol,
            isLeaf: true,
          );

  /// The C library of this process.
  static final Libc instance = Libc._(DynamicLibrary.process());

  /// Name of the function that returns the address of `errno`.
  static String get _errnoSymbol => Platform.isAndroid
      ? '__errno'
      : Platform.isMacOS || Platform.isIOS
      ? '__error'
      : '__errno_location';

  static const int _atFdCwd = -100;
  static const int _fOk = 0;

  // Linux and Android, the same on every architecture.
  static const int _oWrOnly = 0x1;
  static const int _oCreat = 0x40;
  static const int _oExcl = 0x80;
  static const int _oCloExec = 0x80000;
  static const int _renameNoReplace = 1;
  static const int _atSymlinkNoFollow = 0x100;
  static const int _atEmptyPath = 0x1000;
  static const int _statxType = 0x1;
  static const int _statxIno = 0x100;
  static const int _statxSize = 0x200;
  static const int _statxBasicStats = 0x7ff;

  final DynamicLibrary _lib;
  final int Function(Pointer<Utf8>, int) _access;
  final int Function(Pointer<Utf8>, int) _mkdir;
  final int Function(Pointer<Utf8>, int, int) _open;
  final int Function(int) _close;
  final Pointer<Int32> Function() _errno;

  late final int Function(int, Pointer<Utf8>, int, Pointer<Utf8>, int)?
  _renameat2 = _lib.providesSymbol('renameat2')
      ? _lib.lookupFunction<
          Int32 Function(Int32, Pointer<Utf8>, Int32, Pointer<Utf8>, Uint32),
          int Function(int, Pointer<Utf8>, int, Pointer<Utf8>, int)
        >('renameat2', isLeaf: true)
      : null;

  late final int Function(int, Pointer<Utf8>, int, int, Pointer<Uint8>)?
  _statx = _lib.providesSymbol('statx')
      ? _lib.lookupFunction<
          Int32 Function(Int32, Pointer<Utf8>, Int32, Uint32, Pointer<Uint8>),
          int Function(int, Pointer<Utf8>, int, int, Pointer<Uint8>)
        >('statx', isLeaf: true)
      : null;

  /// The `errno` of the call that just failed. Callers read it right after
  /// the call, before anything else can change it.
  int get lastErrno => _errno().value;

  /// `access(path, F_OK)`: 0 if something exists at [path], otherwise the
  /// `errno` of the failure (`ENOENT`, `EACCES`, ...).
  ///
  /// Follows symbolic links (a broken link reports `ENOENT`), so callers
  /// look for links without following them first.
  int accessErrno(String path) => using((arena) {
    final rc = _access(path.toNativeUtf8(allocator: arena), _fOk);
    return rc == 0 ? 0 : lastErrno;
  });

  /// `mkdir(path, 0777)` (the umask applies). Fails with `EEXIST` if
  /// anything is at [path].
  int mkdir(String path) => using((arena) {
    final rc = _mkdir(path.toNativeUtf8(allocator: arena), 511 /* 0777 */);
    return rc == 0 ? 0 : lastErrno;
  });

  /// Whether the system offers `renameat2` and `statx`, which moves need.
  bool get canMove => _renameat2 != null && _statx != null;

  /// `renameat2(from, to, RENAME_NOREPLACE)`: moves [from] to [to] only if
  /// nothing is at [to] (`EEXIST` otherwise). `ENOSYS` if the system has no
  /// `renameat2`.
  int renameNoReplace(String from, String to) {
    final renameat2 = _renameat2;
    if (renameat2 == null) {
      return _enoSys;
    }
    return using((arena) {
      final rc = renameat2(
        _atFdCwd,
        from.toNativeUtf8(allocator: arena),
        _atFdCwd,
        to.toNativeUtf8(allocator: arena),
        _renameNoReplace,
      );
      return rc == 0 ? 0 : lastErrno;
    });
  }

  /// Creates an empty file at [path] only if nothing is there
  /// (`open(O_CREAT | O_EXCL)`), and returns what it is. `EEXIST` if [path]
  /// is taken.
  ({FileIdentity? created, int errno}) createExclusive(String path) {
    final (:reservation, :errno) = reserve(path);
    reservation?.release();
    return (created: reservation?.identity, errno: errno);
  }

  /// Like [createExclusive], but keeps the new file open until
  /// [Reservation.release]. While it is open its inode stays allocated, so
  /// no other file can get the same identity even if this one is removed
  /// and another is created at [path].
  ({Reservation? reservation, int errno}) reserve(String path) {
    final statx = _statx;
    if (statx == null) {
      return (reservation: null, errno: _enoSys);
    }
    return using((arena) {
      final fd = _open(
        path.toNativeUtf8(allocator: arena),
        _oWrOnly | _oCreat | _oExcl | _oCloExec,
        438, // 0666, the umask applies
      );
      if (fd < 0) {
        return (reservation: null, errno: lastErrno);
      }
      // The descriptor names our file for sure, whatever happens at [path].
      final described = _describe(
        arena,
        (buffer) => statx(
          fd,
          ''.toNativeUtf8(allocator: arena),
          _atEmptyPath,
          _statxBasicStats,
          buffer,
        ),
      );
      final info = described.info;
      if (info == null) {
        _close(fd);
        return (reservation: null, errno: described.errno);
      }
      return (
        reservation: Reservation._(info.identity, () => _close(fd)),
        errno: 0,
      );
    });
  }

  /// What is at [path] itself, without following a link there; `null` and
  /// the `errno` if it cannot be described.
  ({FileInfo? info, int errno}) lstat(String path) {
    final statx = _statx;
    if (statx == null) {
      return (info: null, errno: _enoSys);
    }
    return using(
      (arena) => _describe(
        arena,
        (buffer) => statx(
          _atFdCwd,
          path.toNativeUtf8(allocator: arena),
          _atSymlinkNoFollow,
          _statxBasicStats,
          buffer,
        ),
      ),
    );
  }

  /// Calls [call] with a `struct statx` buffer and reads it. The layout is
  /// the same on every Linux architecture.
  ({FileInfo? info, int errno}) _describe(
    Arena arena,
    int Function(Pointer<Uint8> buffer) call,
  ) {
    final buffer = arena<Uint8>(256);
    if (call(buffer) != 0) {
      return (info: null, errno: lastErrno);
    }
    final mask = buffer.cast<Uint32>().value;
    const needed = _statxType | _statxIno | _statxSize;
    if (mask & needed != needed) {
      return (info: null, errno: _enoSys);
    }
    final mode = (buffer + 28).cast<Uint16>().value;
    return (
      info: FileInfo(
        identity: FileIdentity(
          device:
              ((buffer + 136).cast<Uint32>().value << 32) |
              (buffer + 140).cast<Uint32>().value,
          inode: (buffer + 32).cast<Uint64>().value,
        ),
        isRegularFile: mode & 0xf000 == 0x8000,
        size: (buffer + 40).cast<Uint64>().value,
      ),
      errno: 0,
    );
  }

  /// `ENOSYS`: the function is not implemented.
  static const int _enoSys = 38;
}

/// A file that [Libc.reserve] created and keeps open.
final class Reservation {
  Reservation._(this.identity, this._close);

  /// Which file it is.
  final FileIdentity identity;

  final void Function() _close;
  bool _released = false;

  /// Closes the file. Calling it again does nothing.
  void release() {
    if (!_released) {
      _released = true;
      _close();
    }
  }
}

/// Which file an inode is: device and inode number.
@immutable
final class FileIdentity {
  const FileIdentity({required this.device, required this.inode});

  final int device;
  final int inode;

  @override
  bool operator ==(Object other) =>
      other is FileIdentity && other.device == device && other.inode == inode;

  @override
  int get hashCode => Object.hash(device, inode);

  @override
  String toString() => 'FileIdentity($device:$inode)';
}

/// What `lstat` found at a path.
@immutable
final class FileInfo {
  const FileInfo({
    required this.identity,
    required this.isRegularFile,
    required this.size,
  });

  final FileIdentity identity;
  final bool isRegularFile;
  final int size;
}
