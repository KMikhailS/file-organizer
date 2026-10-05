import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/classification.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/layout_folder_names.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:meta/meta.dart';

/// Where a file goes according to the template.
@immutable
sealed class Placement {
  const Placement();
}

/// The file goes into [folder] (the name is chosen by `NameAllocator`).
final class PlaceIn extends Placement {
  const PlaceIn(this.folder);

  final LogicalPath folder;

  @override
  bool operator ==(Object other) => other is PlaceIn && other.folder == folder;

  @override
  int get hashCode => folder.hashCode;

  @override
  String toString() => 'PlaceIn($folder)';
}

/// The file stays where it is.
final class StaysInPlace extends Placement {
  const StaysInPlace(this.reason);

  final StayReason reason;

  @override
  bool operator ==(Object other) =>
      other is StaysInPlace && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'StaysInPlace(${reason.name})';
}

enum StayReason {
  /// The rules are not sure of the category.
  unresolved,

  /// The file already lies in its target folder.
  alreadyInPlace,
}

/// The fixed folder template:
///
/// ```
/// <documents>/
/// <photos>/<year>/
/// <videos>/<year>/
/// <screenshots>/<year>/
/// <music>/
/// <archives>/
/// <installers>/
/// <other>/
/// ```
///
/// Folder names come from the app's localization; the core has none of its
/// own. Optional AI subfolders go after the year.
@immutable
final class LayoutTemplate {
  /// Creates a template under [root] (default: the source root).
  ///
  /// [folderNames] must name every category except
  /// [Category.unresolved] with a distinct (case-insensitively) single
  /// folder name that does not start with a dot; otherwise throws
  /// [ArgumentError].
  ///
  /// [yearOf] turns a UTC date into the year of the year folder. By default
  /// the UTC year; the app passes the local one, so a photo taken just after
  /// midnight on January 1 goes into the new year.
  LayoutTemplate({
    required Map<Category, String> folderNames,
    this.root = LogicalPath.root,
    int Function(DateTime utc)? yearOf,
  }) : folderNames = Map.unmodifiable(folderNames),
       _yearOf = yearOf ?? _utcYear {
    checkLayoutFolderNames(folderNames);
  }

  /// Categories whose files go into year subfolders.
  static const Set<Category> byYear = {
    Category.photos,
    Category.videos,
    Category.screenshots,
  };

  final Map<Category, String> folderNames;

  final LogicalPath root;

  final int Function(DateTime utc) _yearOf;

  /// The top-level folder of [category] (no year).
  LogicalPath folderOf(Category category) {
    final name = folderNames[category];
    if (name == null) {
      throw ArgumentError.value(category, 'category', 'has no folder');
    }
    return root.child(name);
  }

  /// All top-level template folders, for the zones.
  Set<LogicalPath> get targetFolders => {
    for (final category in Category.values)
      if (category != Category.unresolved) folderOf(category),
  };

  /// Where [file] goes given its [classification].
  ///
  /// The year is that of `capturedAt`, else of `modifiedAt`. A file whose
  /// folder already is the target (compared case-insensitively) stays.
  Placement place(FileEntry file, Classification classification) {
    final category = classification.category;
    if (category == Category.unresolved) {
      return const StaysInPlace(StayReason.unresolved);
    }
    var folder = folderOf(category);
    if (byYear.contains(category)) {
      folder = folder.child('${_yearOf(file.capturedAt ?? file.modifiedAt)}');
    }
    if (classification.subfolder case final subfolder?) {
      folder = folder.join(subfolder);
    }
    if (file.path.parent!.value.toLowerCase() == folder.value.toLowerCase()) {
      return const StaysInPlace(StayReason.alreadyInPlace);
    }
    return PlaceIn(folder);
  }

  static int _utcYear(DateTime utc) => utc.toUtc().year;
}
