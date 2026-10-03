import 'package:file_organizer/core/internal/list_equals.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:meta/meta.dart';

/// One page of a file listing.
@immutable
final class FileListPage {
  FileListPage({
    required Iterable<FileEntry> entries,
    required this.cursor,
    Iterable<LogicalPath> inaccessible = const [],
  }) : entries = List.unmodifiable(entries),
       inaccessible = List.unmodifiable(inaccessible);

  /// Files of this page, without hashes. Unmodifiable.
  final List<FileEntry> entries;

  /// Folders that could not be read (for example, permission denied); their
  /// contents are missing from the listing. Unmodifiable.
  final List<LogicalPath> inaccessible;

  /// Pass to `FileSource.list` to resume after this page.
  final ScanCursor cursor;

  @override
  bool operator ==(Object other) =>
      other is FileListPage &&
      other.cursor == cursor &&
      listEquals(other.entries, entries) &&
      listEquals(other.inaccessible, inaccessible);

  @override
  int get hashCode => Object.hash(
    cursor,
    Object.hashAll(entries),
    Object.hashAll(inaccessible),
  );

  @override
  String toString() =>
      'FileListPage(${entries.length} files, '
      '${inaccessible.length} inaccessible, $cursor)';
}
