import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:meta/meta.dart';

/// A user rule that puts matching files into a category. User rules come
/// before the built-in ones; among user rules, a lower [priority] comes
/// first (then [id]).
///
/// All conditions that are set must hold. A rule with
/// [Category.unresolved] keeps matching files where they are.
@immutable
final class ClassificationRule {
  /// Throws [ArgumentError] if no condition is set or [id] is empty.
  ClassificationRule({
    required this.id,
    required this.category,
    this.priority = 0,
    Set<String> extensions = const {},
    String? nameContains,
    this.folder,
    this.sourceId,
  }) : extensions = Set.unmodifiable({
         for (final e in extensions) e.toLowerCase().replaceFirst('.', ''),
       }),
       nameContains = nameContains?.toLowerCase() {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (this.extensions.isEmpty &&
        (this.nameContains?.isEmpty ?? true) &&
        folder == null) {
      throw ArgumentError('a rule needs at least one condition');
    }
  }

  final String id;

  final Category category;

  /// Lower comes first.
  final int priority;

  /// Matching extensions, lower case without the dot; empty means any.
  final Set<String> extensions;

  /// Text the file name must contain, lower case; `null` means any.
  final String? nameContains;

  /// Folder the file must be in, at any depth; `null` means anywhere.
  final LogicalPath? folder;

  /// Source the rule applies to; `null` means all sources.
  final SourceId? sourceId;

  /// Whether [file] meets every condition. Names and folders are compared
  /// case-insensitively.
  bool matches(FileEntry file) {
    if (sourceId != null && file.sourceId != sourceId) {
      return false;
    }
    if (extensions.isNotEmpty && !extensions.contains(file.extension)) {
      return false;
    }
    if (nameContains case final text? when text.isNotEmpty) {
      if (!file.name.toLowerCase().contains(text)) {
        return false;
      }
    }
    if (folder case final folder?) {
      final path = file.path.value.toLowerCase();
      final prefix = folder.value.toLowerCase();
      if (!folder.isRoot && !path.startsWith('$prefix/')) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is ClassificationRule &&
      other.id == id &&
      other.category == category &&
      other.priority == priority &&
      other.extensions.length == extensions.length &&
      other.extensions.containsAll(extensions) &&
      other.nameContains == nameContains &&
      other.folder == folder &&
      other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(
    id,
    category,
    priority,
    Object.hashAllUnordered(extensions),
    nameContains,
    folder,
    sourceId,
  );

  @override
  String toString() =>
      'ClassificationRule($id -> ${category.name}, priority: $priority, '
      'extensions: $extensions, nameContains: $nameContains, '
      'folder: $folder, source: $sourceId)';
}
