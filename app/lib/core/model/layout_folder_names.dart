import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/logical_path.dart';

/// Checks the folder names of the layout template (`LayoutTemplate`,
/// `Settings.layoutFolderNames`).
///
/// [names] must name every category except [Category.unresolved] with a
/// distinct (case-insensitively) single folder name that does not start
/// with a dot; otherwise throws [ArgumentError].
void checkLayoutFolderNames(Map<Category, String> names) {
  final seen = <String>{};
  for (final category in Category.values) {
    final name = names[category];
    if (category == Category.unresolved) {
      if (name != null) {
        throw ArgumentError('unresolved files have no folder');
      }
      continue;
    }
    if (name == null) {
      throw ArgumentError('no folder name for ${category.name}');
    }
    if (name.isEmpty ||
        name.contains('/') ||
        name.startsWith('.') ||
        LogicalPath.problemWith(name) != null) {
      throw ArgumentError.value(name, category.name, 'not a folder name');
    }
    if (!seen.add(name.toLowerCase())) {
      throw ArgumentError.value(name, category.name, 'used twice');
    }
  }
}
