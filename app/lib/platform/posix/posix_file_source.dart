import 'dart:io' as io;

import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/quarantine_ref.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:file_organizer/core/ports/cancel_token.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_list_page.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/file_stat.dart';
import 'package:file_organizer/platform/posix/hash_worker.dart';
import 'package:file_organizer/platform/posix/libc.dart';
import 'package:file_organizer/platform/posix/posix_lister.dart';
import 'package:file_organizer/platform/posix/posix_paths.dart';

/// A [FileSource] over a folder of a POSIX file system: Android shared
/// storage, and Linux and macOS folders in stage 3
/// (`docs/stage2_android.md`, section 5.1).
///
/// Symbolic links are never followed: a link at a path is reported as
/// `wrongType`, and paths behind a link to a folder are not part of the
/// source.
///
/// Part I (task 6) reads only: listing, metadata and hashes. Every method
/// that changes files fails with `unsupported` until part II (task 7)
/// enables them after a probe of the file system.
final class PosixFileSource implements FileSource {
  /// [root] is the absolute path of the source folder.
  PosixFileSource({
    required this.sourceId,
    required String root,
    int pageSize = defaultPageSize,
    int hashBlockSize = 1024 * 1024,
  }) : _paths = PosixPaths(root),
       _hasher = HashWorker(blockSize: hashBlockSize) {
    _lister = PosixLister(
      sourceId: sourceId,
      paths: _paths,
      pageSize: pageSize,
    );
  }

  /// Files (and inaccessible folders) per listing page.
  static const int defaultPageSize = 500;

  /// Name of the folder the adapter keeps in the source root for itself.
  static const String appFolderName = '.FileOrganizer';

  @override
  final SourceId sourceId;

  final PosixPaths _paths;
  final HashWorker _hasher;
  late final PosixLister _lister;

  /// For tests: called after each block a hash call has read (`block`
  /// counts from 0). Hashing waits for it, so a test can cancel a token at
  /// an exact block.
  void Function(LogicalPath path, int block)? onHashBlock;

  /// The root folder of the source.
  String get root => _paths.root;

  @override
  SourceCapabilities get capabilities => SourceCapabilities.none;

  @override
  Set<LogicalPath> get appFolders => _appFolders;

  static final Set<LogicalPath> _appFolders = Set.unmodifiable({
    LogicalPath(appFolderName),
  });

  /// Stops the hashing worker. Later hash calls fail with `ioError`.
  void dispose() => _hasher.dispose();

  @override
  Stream<FileResult<FileListPage>> list({
    ScanCursor? after,
    bool Function(LogicalPath folder)? skipFolder,
  }) => _lister.list(after: after, skipFolder: skipFolder);

  @override
  Future<FileResult<FileStat>> stat(LogicalPath path) async {
    final String real;
    switch (await _paths.resolve(path)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        real = value;
    }
    // The root may itself be a link (such as `/sdcard`); it is the source.
    final type = await io.FileSystemEntity.type(real, followLinks: path.isRoot);
    switch (type) {
      case io.FileSystemEntityType.file || io.FileSystemEntityType.directory:
        final stat = await io.FileStat.stat(real);
        final kind = switch (stat.type) {
          io.FileSystemEntityType.file => FileKind.file,
          io.FileSystemEntityType.directory => FileKind.directory,
          // Replaced or removed since the first look.
          _ => null,
        };
        if (kind == null) {
          return _unreadable(real);
        }
        return FileSuccess(
          FileStat(
            kind: kind,
            size: kind == FileKind.file ? stat.size : 0,
            modifiedAt: stat.modified,
          ),
        );
      case io.FileSystemEntityType.notFound:
        return _unreadable(real);
      default:
        // A link, FIFO or socket: not a file of the source.
        return FileFailure.of(
          FileErrorKind.wrongType,
          '$path is a ${type.toString().toLowerCase()}',
        );
    }
  }

  /// Why `dart:io` sees nothing at [real]: it reports "not found" for
  /// missing paths, for paths it may not read and for devices alike.
  Future<FileResult<FileStat>> _unreadable(String real) async {
    final errno = Libc.instance.accessErrno(real);
    if (errno == 0) {
      return FileFailure.of(
        FileErrorKind.wrongType,
        '$real is neither a file nor a folder',
      );
    }
    return FileFailure.of(_paths.missingKindOfErrno(errno));
  }

  @override
  Future<FileResult<bool>> exists(LogicalPath path) async {
    final String real;
    switch (await _paths.resolve(path)) {
      case FileFailure(error: FileError(kind: FileErrorKind.notFound)):
        return const FileSuccess(false);
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        real = value;
    }
    final type = await io.FileSystemEntity.type(real, followLinks: path.isRoot);
    if (type != io.FileSystemEntityType.notFound) {
      // Anything at the name, a link included, takes the name.
      return const FileSuccess(true);
    }
    final errno = Libc.instance.accessErrno(real);
    if (errno == 0) {
      return const FileSuccess(true);
    }
    final kind = _paths.missingKindOfErrno(errno);
    return kind == FileErrorKind.notFound
        ? const FileSuccess(false)
        : FileFailure.of(kind);
  }

  @override
  Future<FileResult<String>> partialHash(
    LogicalPath path, {
    CancelToken? cancel,
  }) => _hash(path, cancel, partial: true);

  @override
  Future<FileResult<String>> fullHash(
    LogicalPath path, {
    CancelToken? cancel,
  }) => _hash(path, cancel, partial: false);

  Future<FileResult<String>> _hash(
    LogicalPath path,
    CancelToken? cancel, {
    required bool partial,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return FileFailure.of(FileErrorKind.cancelled);
    }
    switch (await stat(path)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value) when value.isDirectory:
        return FileFailure.of(FileErrorKind.wrongType, '$path is a folder');
      case FileSuccess():
        break;
    }
    final hook = onHashBlock;
    return _hasher.hash(
      _paths.real(path),
      partial: partial,
      cancel: cancel,
      onBlock: hook == null ? null : (block) => hook(path, block),
    );
  }

  // Changing files comes in part II (task 7), after the capability probe.

  static Future<FileResult<T>> _unsupported<T>() async =>
      FileFailure.of(FileErrorKind.unsupported);

  @override
  Future<FileResult<void>> mkdir(LogicalPath path) => _unsupported();

  @override
  Future<FileResult<void>> move(LogicalPath from, LogicalPath to) =>
      _unsupported();

  @override
  Future<FileResult<QuarantineRef>> quarantine(
    LogicalPath path,
    SessionId sessionId,
  ) => _unsupported();

  @override
  Future<FileResult<QuarantineRef?>> findQuarantined(
    SessionId sessionId,
    LogicalPath original,
  ) => _unsupported();

  @override
  Future<FileResult<void>> restore(QuarantineRef ref, LogicalPath to) =>
      _unsupported();

  @override
  Future<FileResult<void>> removeEmptyDir(LogicalPath path) => _unsupported();

  @override
  Future<FileResult<void>> purgeQuarantined(QuarantineRef ref) =>
      _unsupported();

  @override
  Future<FileResult<void>> addToAlbum(LogicalPath path) => _unsupported();

  @override
  Future<FileResult<void>> removeFromAlbum(LogicalPath path) => _unsupported();
}
