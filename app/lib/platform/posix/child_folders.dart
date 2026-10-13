import 'dart:io';

import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/platform/posix/posix_paths.dart';

/// The names of the folders directly inside [folder] of the source that
/// [paths] maps, for choosing a folder in the settings
/// (`docs/stage2_android.md`, 5.23). Only reads.
///
/// Like the listing, it never follows links: [folder] must not be or lie
/// behind a symbolic link (`wrongType`), and links among its children are
/// left out. Hidden folders (a leading dot), which the cleanup excludes
/// anyway, are left out too. Sorted case-insensitively.
Future<FileResult<List<String>>> childFolders(
  PosixPaths paths,
  LogicalPath folder,
) async {
  final String real;
  switch (await paths.resolve(folder)) {
    case FileSuccess(:final value):
      real = value;
    case FileFailure(:final error):
      return FileFailure(error);
  }
  final type = await FileSystemEntity.type(real, followLinks: false);
  switch (type) {
    case FileSystemEntityType.directory:
      break;
    case FileSystemEntityType.notFound:
      return FileFailure.of(FileErrorKind.notFound, '$folder is gone');
    case FileSystemEntityType.link when !folder.isRoot:
      return FileFailure.of(FileErrorKind.wrongType, '$folder is a link');
    case FileSystemEntityType.link:
      // The root itself may be a link (as in the listing).
      break;
    default:
      return FileFailure.of(FileErrorKind.wrongType, '$folder is a file');
  }
  try {
    final names = [
      await for (final entity in Directory(real).list(followLinks: false))
        if (entity is Directory)
          entity.path.substring(entity.path.lastIndexOf('/') + 1),
    ]..removeWhere((name) => name.startsWith('.'));
    names.sort((a, b) {
      final folded = a.toLowerCase().compareTo(b.toLowerCase());
      return folded != 0 ? folded : a.compareTo(b);
    });
    return FileSuccess(names);
  } on FileSystemException catch (e) {
    return FileFailure.of(paths.missingKindOf(e), e.message);
  }
}
