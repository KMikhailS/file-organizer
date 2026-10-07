import 'dart:io' as io;
import 'dart:math';

import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/quarantine_ref.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:file_organizer/core/ports/cancel_token.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_list_page.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/file_stat.dart';
import 'package:file_organizer/platform/posix/errno_kind.dart';
import 'package:file_organizer/platform/posix/hash_worker.dart';
import 'package:file_organizer/platform/posix/libc.dart';
import 'package:file_organizer/platform/posix/move_probe.dart';
import 'package:file_organizer/platform/posix/no_replace_mover.dart';
import 'package:file_organizer/platform/posix/posix_lister.dart';
import 'package:file_organizer/platform/posix/posix_paths.dart';
import 'package:file_organizer/platform/posix/quarantine_layout.dart';
import 'package:meta/meta.dart';

/// A [FileSource] over a folder of a POSIX file system: Android shared
/// storage, and Linux and macOS folders in stage 3
/// (`docs/stage2_android.md`, sections 5.1, 5.5 and 5.7).
///
/// - Symbolic links are never followed: a link at a path is reported as
///   `wrongType`, and paths behind a link to a folder are not part of the
///   source.
/// - Nothing is ever replaced: files move only through the [MoveMechanism]
///   that the probe of [open] chose; `mkdir` fails on a taken name.
/// - Nothing is ever deleted except by [purgeQuarantined] (a quarantined
///   file, its description and its empty session folder) and
///   [removeEmptyDir] (an empty folder).
/// - The adapter's own folder `.FileOrganizer` (quarantine, probe files) is
///   not listed and cannot be changed through the port.
final class PosixFileSource implements FileSource {
  PosixFileSource._({
    required this.sourceId,
    required this._paths,
    required this._clock,
    required int pageSize,
    required int hashBlockSize,
    required ProbeResult probe,
  }) : _hasher = HashWorker(blockSize: hashBlockSize),
       moveMechanism = probe.mechanism,
       probeProblem = probe.problem {
    _lister = PosixLister(
      sourceId: sourceId,
      paths: _paths,
      pageSize: pageSize,
      hiddenRootFolder: AppFolder.name,
    );
    final mechanism = probe.mechanism;
    _mover = mechanism == null ? null : _moverFor(_paths, _clock, mechanism);
  }

  /// Opens the source at [root] (an absolute path) and probes what it can
  /// do. A source whose probe fails (no `.FileOrganizer` can be created, no
  /// move without replacing works) can still be listed and hashed; it just
  /// has no capabilities.
  ///
  /// [forceMechanism] is for tests: the fallback of decision A.5 runs on a
  /// file system that supports the main mechanism too.
  static Future<PosixFileSource> open({
    required SourceId sourceId,
    required String root,
    required Clock clock,
    int pageSize = defaultPageSize,
    int hashBlockSize = 1024 * 1024,
    @visibleForTesting MoveMechanism? forceMechanism,
  }) async {
    final paths = PosixPaths(root);
    final probe =
        io.FileSystemEntity.typeSync(paths.root) ==
            io.FileSystemEntityType.directory
        ? probeMoves(
            paths: paths,
            mover: (mechanism) => _moverFor(paths, clock, mechanism),
            force: forceMechanism,
          )
        : (mechanism: null, problem: 'the source root is not a folder');
    return PosixFileSource._(
      sourceId: sourceId,
      paths: paths,
      clock: clock,
      pageSize: pageSize,
      hashBlockSize: hashBlockSize,
      probe: probe,
    );
  }

  /// Files (and inaccessible folders) per listing page.
  static const int defaultPageSize = 500;

  @override
  final SourceId sourceId;

  /// How this source moves files, or `null` if it cannot (read-only).
  final MoveMechanism? moveMechanism;

  /// Why the probe found no way to move files, or `null`.
  final String? probeProblem;

  final PosixPaths _paths;
  final Clock _clock;
  final HashWorker _hasher;
  late final PosixLister _lister;
  late final NoReplaceMover? _mover;

  /// Makes set-aside names unique within this process.
  static int _suffixes = 0;

  /// For tests: called after each block a hash call has read (`block`
  /// counts from 0). Hashing waits for it, so a test can cancel a token at
  /// an exact block.
  void Function(LogicalPath path, int block)? onHashBlock;

  /// The root folder of the source.
  String get root => _paths.root;

  @override
  SourceCapabilities get capabilities => _mover == null
      ? SourceCapabilities.none
      : const SourceCapabilities(
          canMove: true,
          canMkdir: true,
          canQuarantine: true,
          quarantineRestorable: true,
        );

  @override
  Set<LogicalPath> get appFolders => _appFolders;

  static final Set<LogicalPath> _appFolders = Set.unmodifiable({
    AppFolder.root,
  });

  /// Stops the hashing worker. Later hash calls fail with `ioError`.
  void dispose() => _hasher.dispose();

  static NoReplaceMover _moverFor(
    PosixPaths paths,
    Clock clock,
    MoveMechanism mechanism,
  ) => NoReplaceMover(
    mechanism: mechanism,
    setAsideFolder: paths.real(AppFolder.placeholders),
    uniqueSuffix: () => '${clock.now().microsecondsSinceEpoch}-${_suffixes++}',
  );

  @override
  Stream<FileResult<FileListPage>> list({
    ScanCursor? after,
    bool Function(LogicalPath folder)? skipFolder,
  }) => _lister.list(after: after, skipFolder: skipFolder);

  @override
  Future<FileResult<FileStat>> stat(LogicalPath path) async =>
      switch (await _located(path)) {
        FileSuccess(value: (real: _, :final stat)) => FileSuccess(stat),
        FileFailure(:final error) => FileFailure(error),
      };

  /// The real path of [path] and what is there.
  Future<FileResult<({String real, FileStat stat})>> _located(
    LogicalPath path,
  ) async {
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
        return FileSuccess((
          real: real,
          stat: FileStat(
            kind: kind,
            size: kind == FileKind.file ? stat.size : 0,
            modifiedAt: stat.modified,
          ),
        ));
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
  Future<FileResult<T>> _unreadable<T>(String real) async {
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

  // ------------------------------------------------------------- changes

  /// The real path of the regular file at [path].
  Future<FileResult<String>> _file(LogicalPath path) async =>
      switch (await _located(path)) {
        FileSuccess(value: (:final real, :final stat)) when stat.isFile =>
          FileSuccess(real),
        FileSuccess() => FileFailure.of(
          FileErrorKind.wrongType,
          '$path is a folder',
        ),
        FileFailure(:final error) => FileFailure(error),
      };

  /// The real path of [path], refused inside the app folder.
  Future<FileResult<String>> _userPath(LogicalPath path) async =>
      AppFolder.contains(path)
      ? FileFailure.of(
          FileErrorKind.permissionDenied,
          '$path is in the folder of the app',
        )
      : _paths.resolve(path);

  @override
  Future<FileResult<void>> mkdir(LogicalPath path) async {
    if (!capabilities.canMkdir) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    if (path.isRoot) {
      return FileFailure.of(FileErrorKind.targetExists, 'the source root');
    }
    final String real;
    switch (await _userPath(path)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        real = value;
    }
    final errno = Libc.instance.mkdir(real);
    return errno == 0
        ? succeeded
        : FileFailure.of(_paths.missingKindOfErrno(errno), '$path: $errno');
  }

  @override
  Future<FileResult<void>> move(LogicalPath from, LogicalPath to) async {
    final mover = _mover;
    if (mover == null) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    if (AppFolder.contains(from)) {
      return FileFailure.of(
        FileErrorKind.permissionDenied,
        '$from is in the folder of the app',
      );
    }
    final String realFrom;
    switch (await _file(from)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        realFrom = value;
    }
    final String realTo;
    switch (await _userPath(to)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        realTo = value;
    }
    return mover.move(realFrom, realTo);
  }

  @override
  Future<FileResult<QuarantineRef>> quarantine(
    LogicalPath path,
    SessionId sessionId,
  ) async {
    final mover = _mover;
    if (mover == null) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    final folder = AppFolder.sessionFolder(sessionId);
    if (folder == null) {
      return FileFailure.of(FileErrorKind.ioError, 'session id $sessionId');
    }
    if (AppFolder.contains(path)) {
      return FileFailure.of(
        FileErrorKind.permissionDenied,
        '$path is in the folder of the app',
      );
    }
    final String real;
    final FileStat stat;
    switch (await _located(path)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(value: (real: _, stat: final s)) when !s.isFile:
        return FileFailure.of(FileErrorKind.wrongType, '$path is a folder');
      case FileSuccess(:final value):
        (real, stat) = (value.real, value.stat);
    }
    for (final dir in [AppFolder.quarantine, folder]) {
      final errno = Libc.instance.mkdir(_paths.real(dir));
      if (errno != 0 &&
          !(errno == Errno.exist &&
              io.FileSystemEntity.typeSync(
                    _paths.real(dir),
                    followLinks: false,
                  ) ==
                  io.FileSystemEntityType.directory)) {
        return FileFailure.of(
          fileErrorKindOf(errno, _paths.flavor),
          'quarantine folder $dir: $errno',
        );
      }
    }

    // The description first: creating it exclusively takes the number, and
    // a crash before the move leaves only a description without a file.
    final description = QuarantineDescription(
      original: path,
      size: stat.size,
      modifiedAt: stat.modifiedAt,
      quarantinedAt: _clock.now(),
    );
    final taken = await _numbers(folder);
    var n = taken.isEmpty ? 1 : taken.reduce(max) + 1;
    for (; ; n++) {
      final file = _paths.real(folder.child('$n.json'));
      final (:created, :errno) = Libc.instance.createExclusive(file);
      if (created != null) {
        try {
          await io.File(file).writeAsString(description.encode(), flush: true);
        } on io.FileSystemException catch (e) {
          return FileFailure.of(_kindOf(e), 'quarantine description: $e');
        }
        break;
      }
      if (errno != Errno.exist || n > taken.length + 1000) {
        return FileFailure.of(
          fileErrorKindOf(errno, _paths.flavor),
          'quarantine description $n: $errno',
        );
      }
    }
    return switch (mover.move(real, _paths.real(folder.child('$n')))) {
      FileSuccess() => FileSuccess(AppFolder.ref(sessionId, n)),
      FileFailure(:final error) => FileFailure(error),
    };
  }

  /// Numbers used in the quarantine [folder], by files and descriptions.
  Future<List<int>> _numbers(LogicalPath folder) async {
    try {
      return [
        await for (final entity in io.Directory(
          _paths.real(folder),
        ).list(followLinks: false))
          ?AppFolder.numberOf(_nameOf(entity)),
      ];
    } on io.FileSystemException {
      return const [];
    }
  }

  static String _nameOf(io.FileSystemEntity entity) =>
      entity.path.substring(entity.path.lastIndexOf('/') + 1);

  @override
  Future<FileResult<QuarantineRef?>> findQuarantined(
    SessionId sessionId,
    LogicalPath original,
  ) async {
    if (_mover == null) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    final folder = AppFolder.sessionFolder(sessionId);
    if (folder == null) {
      return const FileSuccess(null);
    }
    final numbers = (await _numbers(folder)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    for (final n in numbers) {
      final QuarantineDescription? description;
      try {
        description = QuarantineDescription.decode(
          await io.File(_paths.real(folder.child('$n.json'))).readAsString(),
        );
      } on io.FileSystemException {
        continue;
      }
      if (description == null || description.original != original) {
        continue;
      }
      final file = Libc.instance.lstat(_paths.real(folder.child('$n'))).info;
      if (file != null && file.isRegularFile && file.size == description.size) {
        return FileSuccess(AppFolder.ref(sessionId, n));
      }
    }
    return const FileSuccess(null);
  }

  @override
  Future<FileResult<void>> restore(QuarantineRef ref, LogicalPath to) async {
    final mover = _mover;
    if (mover == null) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    final located = AppFolder.locate(ref);
    if (located == null) {
      return FileFailure.of(FileErrorKind.notFound, 'not a reference: $ref');
    }
    final String realFile;
    switch (await _file(located.file)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        realFile = value;
    }
    final String realTo;
    switch (await _userPath(to)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        realTo = value;
    }
    return mover.move(realFile, realTo);
  }

  @override
  Future<FileResult<void>> removeEmptyDir(LogicalPath path) async {
    if (!capabilities.canMkdir || path.isRoot) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    final String real;
    switch (await _userPath(path)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        real = value;
    }
    switch (await _located(path)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(value: (real: _, :final stat)) when !stat.isDirectory:
        return FileFailure.of(FileErrorKind.wrongType, '$path is a file');
      case FileSuccess():
        break;
    }
    try {
      // Not recursive: rmdir(2), which refuses a folder with anything in it.
      await io.Directory(real).delete();
      return succeeded;
    } on io.FileSystemException catch (e) {
      return FileFailure.of(_kindOf(e), '$path: ${e.message}');
    }
  }

  /// The only deletion of the adapter: the quarantined file of [ref], its
  /// description, and the session folder once it is empty. Nothing outside
  /// `.FileOrganizer/quarantine/` can be named by a reference.
  @override
  Future<FileResult<void>> purgeQuarantined(QuarantineRef ref) async {
    if (_mover == null) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    final located = AppFolder.locate(ref);
    if (located == null) {
      return FileFailure.of(FileErrorKind.notFound, 'not a reference: $ref');
    }
    final String realFile;
    switch (await _file(located.file)) {
      case FileFailure(:final error):
        return FileFailure(error);
      case FileSuccess(:final value):
        realFile = value;
    }
    final realDescription = _paths.real(located.description);
    try {
      await io.File(realFile).delete();
      if (Libc.instance.lstat(realDescription).info?.isRegularFile ?? false) {
        await io.File(realDescription).delete();
      }
    } on io.FileSystemException catch (e) {
      return FileFailure.of(_kindOf(e), '$ref: ${e.message}');
    }
    try {
      // Not recursive: only once the session folder is empty.
      await io.Directory(_paths.real(located.file.parent!)).delete();
    } on io.FileSystemException {
      // Other files of the session are still there.
    }
    return succeeded;
  }

  @override
  Future<FileResult<void>> addToAlbum(LogicalPath path) async =>
      FileFailure.of(FileErrorKind.unsupported);

  @override
  Future<FileResult<void>> removeFromAlbum(LogicalPath path) async =>
      FileFailure.of(FileErrorKind.unsupported);

  FileErrorKind _kindOf(io.FileSystemException e) {
    final errno = e.osError?.errorCode;
    return errno == null
        ? FileErrorKind.ioError
        : fileErrorKindOf(errno, _paths.flavor);
  }
}
