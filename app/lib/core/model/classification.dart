import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:meta/meta.dart';

/// Who produced a classification.
enum ClassificationOrigin { rule, ai }

/// Result of classifying one file.
@immutable
final class Classification {
  /// Creates a classification.
  ///
  /// Throws [ArgumentError] if [confidence] is outside 0..1, if [subfolder]
  /// is the root, or if an [Category.unresolved] classification has a
  /// [subfolder].
  Classification({
    required this.category,
    required this.confidence,
    required this.origin,
    required this.reason,
    this.subfolder,
  }) {
    if (confidence.isNaN || confidence < 0 || confidence > 1) {
      throw ArgumentError.value(confidence, 'confidence', 'must be in 0..1');
    }
    if (subfolder case final subfolder? when subfolder.isRoot) {
      throw ArgumentError.value(subfolder, 'subfolder', 'must not be empty');
    }
    if (category == Category.unresolved && subfolder != null) {
      throw ArgumentError.value(
        subfolder,
        'subfolder',
        'an unresolved file has no target folder',
      );
    }
  }

  final Category category;

  /// Optional folder inside the category folder (from AI; not used in
  /// stage 1). Being a [LogicalPath], it cannot escape the category folder.
  final LogicalPath? subfolder;

  /// How sure the classifier is, from 0 to 1.
  final double confidence;

  final ClassificationOrigin origin;

  /// Human-readable explanation.
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is Classification &&
      other.category == category &&
      other.subfolder == subfolder &&
      other.confidence == confidence &&
      other.origin == origin &&
      other.reason == reason;

  @override
  int get hashCode =>
      Object.hash(category, subfolder, confidence, origin, reason);

  @override
  String toString() =>
      'Classification($category, subfolder: $subfolder, '
      'confidence: $confidence, $origin, "$reason")';
}
