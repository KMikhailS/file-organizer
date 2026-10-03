import 'package:file_organizer/core/model/classification.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:meta/meta.dart';

/// A file to classify and its context.
@immutable
final class ClassificationRequest {
  const ClassificationRequest({required this.file, required this.zone});

  final FileEntry file;

  /// Zone of the folder the file is in.
  final Zone zone;

  @override
  bool operator ==(Object other) =>
      other is ClassificationRequest &&
      other.file == file &&
      other.zone == zone;

  @override
  int get hashCode => Object.hash(file, zone);

  @override
  String toString() => 'ClassificationRequest(${file.path}, ${zone.name})';
}

/// Determines the category of files.
///
/// Implementations: rules in the core, a cloud classifier later (outside the
/// core), a fake in tests. A classifier that cannot decide returns
/// `Category.unresolved` instead of failing.
abstract interface class Classifier {
  /// One classification per request, in the same order.
  Future<List<Classification>> classify(List<ClassificationRequest> requests);
}
