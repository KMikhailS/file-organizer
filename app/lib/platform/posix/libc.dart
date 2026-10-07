import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// The few functions of the system C library that `dart:io` does not
/// offer. Works with glibc (Linux), bionic (Android) and the macOS libc.
///
/// Only functions that read are bound here. Calls that change files are
/// added together with their checks (`docs/stage2_android.md`, decision
/// A.5 and section 11).
final class Libc {
  Libc._(DynamicLibrary lib)
    : _access = lib
          .lookupFunction<
            Int32 Function(Pointer<Utf8>, Int32),
            int Function(Pointer<Utf8>, int)
          >('access', isLeaf: true),
      _errno = lib
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

  /// `F_OK`: only check that the path exists.
  static const int _fOk = 0;

  final int Function(Pointer<Utf8>, int) _access;
  final Pointer<Int32> Function() _errno;

  /// `access(path, F_OK)`: 0 if something exists at [path], otherwise the
  /// `errno` of the failure (`ENOENT`, `EACCES`, ...).
  ///
  /// Follows symbolic links (a broken link reports `ENOENT`), so callers
  /// look for links without following them first.
  int accessErrno(String path) => using((arena) {
    final rc = _access(path.toNativeUtf8(allocator: arena), _fOk);
    return rc == 0 ? 0 : _errno().value;
  });
}
