import 'dart:io';

import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/scan_cursor.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_list_page.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/platform/posix/errno_kind.dart';
import 'package:file_organizer/platform/posix/posix_paths.dart';

/// Lists the files of a POSIX folder tree in pages
/// (`docs/stage2_android.md`, sections 5.1 and 5.5).
///
/// - **Order:** depth first, one folder at a time; the children of a folder
///   are sorted by name (UTF-16 code units). So paths are ordered segment by
///   segment, and a folder comes before everything inside it.
/// - **Cursor:** the logical path of the last item of the page (a file or
///   an inaccessible folder). Resuming skips, on every level of the cursor,
///   the children before its segment and descends into the equal one.
/// - Only regular files are listed. Symbolic links to files, FIFOs, sockets
///   and devices are skipped; symbolic links to folders and folders that
///   cannot be read are reported as inaccessible. A folder with a name that
///   is not valid UTF-8 inside is reported as inaccessible too: its listing
///   is incomplete.
/// - A missing or unreadable root ends the stream with a failure.
final class PosixLister {
  PosixLister({
    required this.sourceId,
    required this.paths,
    required this.pageSize,
  }) {
    if (pageSize < 1) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be positive');
    }
  }

  final SourceId sourceId;
  final PosixPaths paths;

  /// Maximum number of items (files and inaccessible folders) per page.
  final int pageSize;

  /// How many entries of one folder are examined at the same time.
  static const int _statBatch = 64;

  Stream<FileResult<FileListPage>> list({
    ScanCursor? after,
    bool Function(LogicalPath folder)? skipFolder,
  }) async* {
    final List<String>? cursor;
    if (after == null) {
      cursor = null;
    } else if (LogicalPath.problemWith(after.value) != null) {
      yield FileFailure.of(FileErrorKind.ioError, 'invalid cursor $after');
      return;
    } else {
      cursor = LogicalPath(after.value).segments;
    }

    final _DirRead root;
    switch (await _readDir(LogicalPath.root)) {
      case _DirFailed(:final kind, :final message):
        yield FileFailure.of(kind, message);
        return;
      case final _DirRead read:
        root = read;
    }

    final items = <_Item>[];
    final walk = _walk(
      LogicalPath.root,
      root,
      depth: 0,
      cursor: cursor,
      after: after,
      skipFolder: skipFolder,
    );
    await for (final item in walk) {
      items.add(item);
      if (items.length == pageSize) {
        yield FileSuccess(_page(items));
        items.clear();
      }
    }
    if (items.isNotEmpty) {
      yield FileSuccess(_page(items));
    }
  }

  FileListPage _page(List<_Item> items) => FileListPage(
    entries: [for (final item in items) ?item.entry],
    inaccessible: [
      for (final item in items)
        if (item.entry == null) item.path,
    ],
    cursor: items.last.position,
  );

  /// Items inside [dir], whose children are [listing].
  ///
  /// [cursor] is set while [dir] lies on the path of the resume cursor
  /// ([dir] equals its first [depth] segments); [after] is that cursor.
  Stream<_Item> _walk(
    LogicalPath dir,
    _DirRead listing, {
    required int depth,
    required List<String>? cursor,
    required ScanCursor? after,
    required bool Function(LogicalPath folder)? skipFolder,
  }) async* {
    // Items on the cursor path come before the cursor, except what lies
    // strictly inside it. Such a late item keeps the old cursor, so the
    // cursor never moves back.
    final cursorInside = cursor != null && cursor.length > depth;
    _Item inaccessible(LogicalPath path, {required bool late}) =>
        _Item(path, null, late ? after! : ScanCursor(path.value));

    if (listing.incomplete && (cursor == null || cursorInside)) {
      yield inaccessible(dir, late: cursor != null);
    }

    var bound = cursorInside ? cursor[depth] : null;
    for (final child in listing.children) {
      var onCursorPath = false;
      if (bound != null) {
        final order = child.name.compareTo(bound);
        if (order < 0) {
          continue;
        }
        onCursorPath = order == 0;
        bound = null;
      }
      // Whether the cursor lies strictly inside this child.
      final cursorBelow = onCursorPath && cursor!.length > depth + 1;
      final path = dir.child(child.name);

      switch (child) {
        case _FileChild(:final size, :final modifiedAt):
          if (!onCursorPath) {
            final entry = FileEntry(
              sourceId: sourceId,
              path: path,
              size: size,
              modifiedAt: modifiedAt,
            );
            yield _Item(path, entry, ScanCursor(path.value));
          }
        case _LinkedDirChild():
          if (!onCursorPath && !(skipFolder?.call(path) ?? false)) {
            yield inaccessible(path, late: false);
          }
        case _DirChild():
          if (skipFolder?.call(path) ?? false) {
            continue;
          }
          // If the folder itself was the cursor (it was inaccessible),
          // whatever it holds now comes after it.
          switch (await _readDir(path)) {
            case _DirFailed(kind: FileErrorKind.notFound):
              // Removed while listing: nothing to report.
              break;
            case _DirFailed():
              if (!onCursorPath || cursorBelow) {
                yield inaccessible(path, late: cursorBelow);
              }
            case final _DirRead sub:
              yield* _walk(
                path,
                sub,
                depth: depth + 1,
                cursor: onCursorPath ? cursor : null,
                after: after,
                skipFolder: skipFolder,
              );
          }
      }
    }
  }

  /// The children of [dir], sorted by name.
  Future<_DirListing> _readDir(LogicalPath dir) async {
    final realDir = paths.real(dir);
    final List<FileSystemEntity> entities;
    try {
      entities = await Directory(realDir).list(followLinks: false).toList();
    } on FileSystemException catch (e) {
      final errno = e.osError?.errorCode;
      return _DirFailed(
        errno == null
            ? FileErrorKind.ioError
            : fileErrorKindOf(errno, paths.flavor),
        '${dir.isRoot ? 'source root' : dir}: ${e.message}',
      );
    }

    final prefix = realDir == '/' ? '/' : '$realDir/';
    final children = <_Child>[];
    var incomplete = false;
    for (var i = 0; i < entities.length; i += _statBatch) {
      final batch = entities.skip(i).take(_statBatch);
      final results = await Future.wait([
        for (final entity in batch)
          _classify(entity, entity.path.substring(prefix.length)),
      ]);
      for (final result in results) {
        switch (result) {
          case _Undecodable():
            incomplete = true;
          case final _Child child:
            children.add(child);
          case null:
            break;
        }
      }
    }
    children.sort((a, b) => a.name.compareTo(b.name));
    return _DirRead(children, incomplete: incomplete);
  }

  /// What the entry [name] of a folder listing is, or `null` if it is not
  /// listed (links to files, FIFOs, sockets, devices, entries removed while
  /// listing).
  Future<Object?> _classify(FileSystemEntity entity, String name) async {
    final path = entity.path;
    // dart:io decodes names that are not valid UTF-8 with U+FFFD; such a
    // name does not lead back to the entry.
    if (name.contains('�') &&
        await FileSystemEntity.type(path, followLinks: false) ==
            FileSystemEntityType.notFound) {
      return const _Undecodable();
    }
    switch (entity) {
      case Directory():
        return _DirChild(name);
      case Link():
        final target = await FileSystemEntity.type(path);
        return target == FileSystemEntityType.directory
            ? _LinkedDirChild(name)
            : null;
      default:
        final stat = await FileStat.stat(path);
        return stat.type == FileSystemEntityType.file
            ? _FileChild(name, stat.size, stat.modified)
            : null;
    }
  }
}

/// One item of a page: a file ([entry] is set) or an inaccessible folder.
final class _Item {
  const _Item(this.path, this.entry, this.position);

  final LogicalPath path;
  final FileEntry? entry;

  /// The cursor after this item.
  final ScanCursor position;
}

sealed class _DirListing {
  const _DirListing();
}

final class _DirRead extends _DirListing {
  const _DirRead(this.children, {required this.incomplete});

  final List<_Child> children;

  /// Whether some entries could not be read (names not in UTF-8).
  final bool incomplete;
}

final class _DirFailed extends _DirListing {
  const _DirFailed(this.kind, this.message);

  final FileErrorKind kind;
  final String message;
}

sealed class _Child {
  const _Child(this.name);

  final String name;
}

final class _FileChild extends _Child {
  const _FileChild(super.name, this.size, this.modifiedAt);

  final int size;
  final DateTime modifiedAt;
}

final class _DirChild extends _Child {
  const _DirChild(super.name);
}

/// A symbolic link to a folder: never followed, reported as inaccessible.
final class _LinkedDirChild extends _Child {
  const _LinkedDirChild(super.name);
}

/// An entry whose name is not valid UTF-8.
final class _Undecodable {
  const _Undecodable();
}
