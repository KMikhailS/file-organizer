import 'dart:io';

import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/platform/posix/errno_kind.dart';

/// Turns logical paths of one source into real paths under its [root].
///
/// Files behind a symbolic link to a folder are not part of the source
/// (`docs/stage2_android.md`, principle 5: links are never followed), even
/// if the link points inside it: the listing never reports such paths. So
/// [resolve] checks that no folder on the way from the root is a link.
final class PosixPaths {
  /// [root] is an absolute path; a trailing `/` is ignored.
  PosixPaths(String root, {PosixFlavor? flavor})
    : root = _normalize(root),
      flavor = flavor ?? PosixFlavor.current;

  /// The root folder of the source, without a trailing `/` (except `/`).
  final String root;

  final PosixFlavor flavor;

  Future<String>? _realRoot;

  /// The real path of [path], without checks.
  String real(LogicalPath path) {
    if (path.isRoot) {
      return root;
    }
    return root == '/' ? '/${path.value}' : '$root/${path.value}';
  }

  /// The real path of [path] if no folder on its way is a symbolic link.
  ///
  /// Fails with `notFound` if a parent folder is missing (or is a file),
  /// `permissionDenied` if it cannot be reached, and `wrongType` if it is
  /// or lies behind a symbolic link. The root itself may be a link.
  Future<FileResult<String>> resolve(LogicalPath path) async {
    final parent = path.parent;
    if (parent == null || parent.isRoot) {
      return FileSuccess(real(path));
    }
    final String realRoot;
    final String realParent;
    try {
      realRoot = await (_realRoot ??= Directory(root).resolveSymbolicLinks());
    } on FileSystemException catch (e) {
      _realRoot = null;
      return FileFailure.of(missingKindOf(e), 'source root: ${e.message}');
    }
    try {
      realParent = await Directory(real(parent)).resolveSymbolicLinks();
    } on FileSystemException catch (e) {
      return FileFailure.of(missingKindOf(e), e.message);
    }
    // realpath keeps the names it was given and only replaces links, so
    // any difference means a link on the way.
    final expected = realRoot == '/'
        ? '/${parent.value}'
        : '$realRoot/${parent.value}';
    if (realParent != expected) {
      return FileFailure.of(
        FileErrorKind.wrongType,
        '$parent is or lies behind a symbolic link',
      );
    }
    return FileSuccess(real(path));
  }

  /// The error kind of a failed call on a path that may be missing: a path
  /// under a file (`ENOTDIR`) does not exist either.
  FileErrorKind missingKindOf(FileSystemException e) {
    final errno = e.osError?.errorCode;
    return errno == null ? FileErrorKind.ioError : missingKindOfErrno(errno);
  }

  /// Like [missingKindOf], for a plain `errno`.
  FileErrorKind missingKindOfErrno(int errno) => errno == Errno.notDir
      ? FileErrorKind.notFound
      : fileErrorKindOf(errno, flavor);

  static String _normalize(String root) {
    if (!root.startsWith('/')) {
      throw ArgumentError.value(root, 'root', 'must be an absolute path');
    }
    var normalized = root;
    while (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
