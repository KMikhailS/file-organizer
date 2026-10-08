import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/quarantine_ref.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:file_organizer/core/ports/cancel_token.dart';
import 'package:file_organizer/core/ports/clock.dart';
import 'package:file_organizer/core/ports/file_list_page.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/ports/file_stat.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/platform/posix/no_replace_mover.dart';
import 'package:file_organizer/platform/posix/posix_file_source.dart';

/// The shared storage of an Android device in "All files access" mode
/// (`docs/stage2_android.md`, sections 5.2 and 5.11).
///
/// Files are read and changed by the POSIX adapter (decision A.3), with the
/// same guarantees: nothing is replaced, nothing is deleted outside the
/// quarantine purge, links are never followed. On top of it, listings carry
/// the capture dates of MediaStore (`DATE_TAKEN`), one query per page.
final class AndroidFileSource implements FileSource {
  AndroidFileSource._(this._posix, this._native);

  /// Opens the storage at [root] (from `AndroidNative.primaryStorageRoot`
  /// in the app; a test folder in tests) and probes what it can do.
  static Future<AndroidFileSource> open({
    required SourceId sourceId,
    required String root,
    required Clock clock,
    required AndroidNative native,
    int pageSize = PosixFileSource.defaultPageSize,
  }) async => AndroidFileSource._(
    await PosixFileSource.open(
      sourceId: sourceId,
      root: root,
      clock: clock,
      pageSize: pageSize,
    ),
    native,
  );

  final PosixFileSource _posix;
  final AndroidNative _native;

  /// How this source moves files, or `null` if it cannot.
  MoveMechanism? get moveMechanism => _posix.moveMechanism;

  /// Why the probe found no way to move files, or `null`.
  String? get probeProblem => _posix.probeProblem;

  /// The root folder of the source.
  String get root => _posix.root;

  /// Stops the hashing worker.
  void dispose() => _posix.dispose();

  @override
  SourceId get sourceId => _posix.sourceId;

  @override
  SourceCapabilities get capabilities {
    final posix = _posix.capabilities;
    return SourceCapabilities(
      canMove: posix.canMove,
      canMkdir: posix.canMkdir,
      canQuarantine: posix.canQuarantine,
      quarantineRestorable: posix.quarantineRestorable,
      providesCapturedAt: true,
    );
  }

  @override
  Set<LogicalPath> get appFolders => _posix.appFolders;

  /// The listing of the POSIX adapter with capture dates. If MediaStore
  /// cannot be asked, the page goes on without dates (decision of the user,
  /// section 5.11): the core then takes the year of the modification time.
  @override
  Stream<FileResult<FileListPage>> list({
    ScanCursor? after,
    bool Function(LogicalPath folder)? skipFolder,
  }) async* {
    await for (final result in _posix.list(
      after: after,
      skipFolder: skipFolder,
    )) {
      switch (result) {
        case FileSuccess(value: final page) when page.entries.isNotEmpty:
          yield FileSuccess(await _withDates(page));
        case _:
          yield result;
      }
    }
  }

  Future<FileListPage> _withDates(FileListPage page) async {
    final realOf = {for (final e in page.entries) e.path: _real(e.path)};
    final Map<String, DateTime> dates;
    switch (await _native.capturedDates(realOf.values)) {
      case NativeOk(:final value):
        dates = value;
      case NativeFailed():
        return page;
    }
    return FileListPage(
      entries: [
        for (final entry in page.entries)
          switch (dates[realOf[entry.path]]) {
            null => entry,
            final capturedAt => FileEntry(
              sourceId: entry.sourceId,
              path: entry.path,
              size: entry.size,
              modifiedAt: entry.modifiedAt,
              capturedAt: capturedAt,
              mimeType: entry.mimeType,
            ),
          },
      ],
      inaccessible: page.inaccessible,
      cursor: page.cursor,
    );
  }

  String _real(LogicalPath path) =>
      root == '/' ? '/${path.value}' : '$root/${path.value}';

  @override
  Future<FileResult<FileStat>> stat(LogicalPath path) => _posix.stat(path);

  @override
  Future<FileResult<bool>> exists(LogicalPath path) => _posix.exists(path);

  @override
  Future<FileResult<String>> partialHash(
    LogicalPath path, {
    CancelToken? cancel,
  }) => _posix.partialHash(path, cancel: cancel);

  @override
  Future<FileResult<String>> fullHash(
    LogicalPath path, {
    CancelToken? cancel,
  }) => _posix.fullHash(path, cancel: cancel);

  @override
  Future<FileResult<void>> mkdir(LogicalPath path) => _posix.mkdir(path);

  @override
  Future<FileResult<void>> move(LogicalPath from, LogicalPath to) =>
      _posix.move(from, to);

  @override
  Future<FileResult<QuarantineRef>> quarantine(
    LogicalPath path,
    SessionId sessionId,
  ) => _posix.quarantine(path, sessionId);

  @override
  Future<FileResult<QuarantineRef?>> findQuarantined(
    SessionId sessionId,
    LogicalPath original,
  ) => _posix.findQuarantined(sessionId, original);

  @override
  Future<FileResult<void>> restore(QuarantineRef ref, LogicalPath to) =>
      _posix.restore(ref, to);

  @override
  Future<FileResult<void>> removeEmptyDir(LogicalPath path) =>
      _posix.removeEmptyDir(path);

  @override
  Future<FileResult<void>> purgeQuarantined(QuarantineRef ref) =>
      _posix.purgeQuarantined(ref);

  @override
  Future<FileResult<void>> addToAlbum(LogicalPath path) =>
      _posix.addToAlbum(path);

  @override
  Future<FileResult<void>> removeFromAlbum(LogicalPath path) =>
      _posix.removeFromAlbum(path);
}
