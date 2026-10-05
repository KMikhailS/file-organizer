// Minimal libc bindings for the A.5 experiment (docs/stage2_android.md,
// section 4). Works with bionic (Android) and glibc (Linux).
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// `AT_FDCWD`: paths are resolved against the current directory.
const int atFdCwd = -100;

/// `RENAME_NOREPLACE`: fail with `EEXIST` instead of replacing the target.
const int renameNoReplace = 1;

/// Linux / Android errno numbers seen in the experiment.
const Map<int, String> errnoNames = {
  1: 'EPERM',
  2: 'ENOENT',
  13: 'EACCES',
  16: 'EBUSY',
  17: 'EEXIST',
  18: 'EXDEV',
  20: 'ENOTDIR',
  21: 'EISDIR',
  22: 'EINVAL',
  30: 'EROFS',
  38: 'ENOSYS',
  39: 'ENOTEMPTY',
  95: 'EOPNOTSUPP',
};

/// Result of one libc call: return code and errno (0 when the call worked).
typedef CallResult = ({int rc, int errno});

/// Human-readable form of [result]: `ok` or `-1 EEXIST`.
String describe(CallResult result) => result.rc == 0
    ? 'ok'
    : '${result.rc} ${errnoNames[result.errno] ?? 'errno ${result.errno}'}';

/// The few libc functions the experiment needs.
final class Libc {
  Libc() : this._(DynamicLibrary.process());

  Libc._(DynamicLibrary lib)
    : _renameat2 = lib
          .lookupFunction<
            Int32 Function(Int32, Pointer<Utf8>, Int32, Pointer<Utf8>, Uint32),
            int Function(int, Pointer<Utf8>, int, Pointer<Utf8>, int)
          >('renameat2', isLeaf: true),
      _link = lib
          .lookupFunction<
            Int32 Function(Pointer<Utf8>, Pointer<Utf8>),
            int Function(Pointer<Utf8>, Pointer<Utf8>)
          >('link', isLeaf: true),
      _mkdir = lib
          .lookupFunction<
            Int32 Function(Pointer<Utf8>, Uint32),
            int Function(Pointer<Utf8>, int)
          >('mkdir', isLeaf: true),
      _rmdir = lib
          .lookupFunction<
            Int32 Function(Pointer<Utf8>),
            int Function(Pointer<Utf8>)
          >('rmdir', isLeaf: true),
      _errno = lib
          .lookupFunction<Pointer<Int32> Function(), Pointer<Int32> Function()>(
            Platform.isAndroid ? '__errno' : '__errno_location',
            isLeaf: true,
          );

  final int Function(int, Pointer<Utf8>, int, Pointer<Utf8>, int) _renameat2;
  final int Function(Pointer<Utf8>, Pointer<Utf8>) _link;
  final int Function(Pointer<Utf8>, int) _mkdir;
  final int Function(Pointer<Utf8>) _rmdir;
  final Pointer<Int32> Function() _errno;

  /// `renameat2(AT_FDCWD, from, AT_FDCWD, to, flags)`.
  CallResult renameat2(String from, String to, int flags) => using(
    (arena) => _call(
      () => _renameat2(
        atFdCwd,
        from.toNativeUtf8(allocator: arena),
        atFdCwd,
        to.toNativeUtf8(allocator: arena),
        flags,
      ),
    ),
  );

  /// `link(from, to)`: a hard link.
  CallResult link(String from, String to) => using(
    (arena) => _call(
      () => _link(
        from.toNativeUtf8(allocator: arena),
        to.toNativeUtf8(allocator: arena),
      ),
    ),
  );

  /// `mkdir(path, 0777)` (the umask applies).
  CallResult mkdir(String path) => using(
    (arena) => _call(
      () => _mkdir(path.toNativeUtf8(allocator: arena), 511 /* 0777 */),
    ),
  );

  /// `rmdir(path)`: removes an empty folder only.
  CallResult rmdir(String path) => using(
    (arena) => _call(() => _rmdir(path.toNativeUtf8(allocator: arena))),
  );

  CallResult _call(int Function() call) {
    final rc = call();
    return (rc: rc, errno: rc == 0 ? 0 : _errno().value);
  }
}
