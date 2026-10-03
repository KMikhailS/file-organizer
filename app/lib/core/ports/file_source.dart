import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/quarantine_ref.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:file_organizer/core/ports/file_list_page.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_stat.dart';

/// Access to the files of one source. Implemented by platform adapters.
///
/// Rules every implementation follows:
/// - Paths are logical paths inside this source; nothing ever leaves it.
/// - Expected failures are returned as [FileFailure], never thrown. A
///   failed call changes nothing.
/// - Nothing is ever overwritten: [move] and [restore] fail with
///   `targetExists` if the target is taken.
/// - Files are never deleted. The only deletion is [purgeQuarantined],
///   which accepts nothing but a [QuarantineRef]. [removeEmptyDir] removes
///   empty folders only; [removeFromAlbum] only takes a photo out of an
///   album and keeps the photo itself.
/// - A method the source cannot perform (see [capabilities]) fails with
///   `unsupported`.
abstract interface class FileSource {
  /// The source this instance works with.
  SourceId get sourceId;

  SourceCapabilities get capabilities;

  /// Folders this adapter keeps inside the source for itself, such as its
  /// own quarantine. They are excluded from every cleanup.
  Set<LogicalPath> get appFolders;

  /// Lists all files of the source in pages, in a stable order.
  ///
  /// With [after], the listing resumes after the page that returned that
  /// cursor. Folders for which [skipFolder] returns `true` are not entered.
  /// Entries have no hashes and no scan id. Folders that cannot be read are
  /// reported in [FileListPage.inaccessible]. A failure ends the stream.
  Stream<FileResult<FileListPage>> list({
    ScanCursor? after,
    bool Function(LogicalPath folder)? skipFolder,
  });

  /// Metadata of [path]; `notFound` if nothing is there.
  Future<FileResult<FileStat>> stat(LogicalPath path);

  /// Whether a file or folder exists at [path].
  Future<FileResult<bool>> exists(LogicalPath path);

  /// Hash of the size and the first and last 64 KB of the file at [path].
  Future<FileResult<String>> partialHash(LogicalPath path);

  /// Hash of the whole content of the file at [path], computed as a stream.
  Future<FileResult<String>> fullHash(LogicalPath path);

  /// Creates the folder [path]. Its parent must exist (one level at a time,
  /// so every created folder is journaled). `targetExists` if anything is
  /// already at [path].
  Future<FileResult<void>> mkdir(LogicalPath path);

  /// Moves the file at [from] to [to]. The parent of [to] must exist.
  /// Never overwrites: `targetExists` if anything is at [to].
  Future<FileResult<void>> move(LogicalPath from, LogicalPath to);

  /// Takes the file at [path] out of the way into this source's quarantine
  /// (own quarantine folder or system trash) and returns a reference to it.
  Future<FileResult<QuarantineRef>> quarantine(
    LogicalPath path,
    SessionId sessionId,
  );

  /// Finds the object that [quarantine] made for the file at [original] in
  /// session [sessionId], or `null` if there is none (never quarantined, or
  /// purged). Read-only: lets crash recovery find a reference that was not
  /// journaled yet.
  Future<FileResult<QuarantineRef?>> findQuarantined(
    SessionId sessionId,
    LogicalPath original,
  );

  /// Puts the quarantined file [ref] back at [to]. Never overwrites:
  /// `targetExists` if anything is at [to]; `notFound` if [ref] was purged.
  Future<FileResult<void>> restore(QuarantineRef ref, LogicalPath to);

  /// Removes the folder [path] if it is empty; `notEmpty` otherwise.
  Future<FileResult<void>> removeEmptyDir(LogicalPath path);

  /// Permanently deletes the quarantined file [ref]. The only deletion in
  /// the system.
  Future<FileResult<void>> purgeQuarantined(QuarantineRef ref);

  /// Adds the photo at [path] to the "to delete" album (iOS Photos). The
  /// photo stays where it is.
  Future<FileResult<void>> addToAlbum(LogicalPath path);

  /// Takes the photo at [path] out of the "to delete" album. The photo itself
  /// is not deleted.
  Future<FileResult<void>> removeFromAlbum(LogicalPath path);
}
