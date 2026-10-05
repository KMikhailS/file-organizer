import 'package:meta/meta.dart';

/// Why a file got its category: a code with parameters. The UI turns it into
/// text through localization; the core never produces user-facing text.
@immutable
sealed class ClassificationReason {
  const ClassificationReason();
}

/// A user rule matched.
final class ByUserRule extends ClassificationReason {
  const ByUserRule(this.ruleId);

  /// `ClassificationRule.id`.
  final String ruleId;

  @override
  bool operator ==(Object other) =>
      other is ByUserRule && other.ruleId == ruleId;

  @override
  int get hashCode => Object.hash(ByUserRule, ruleId);

  @override
  String toString() => 'ByUserRule($ruleId)';
}

/// The extension decided the category.
final class ByExtension extends ClassificationReason {
  const ByExtension(this.extension);

  /// Lower case, without the dot.
  final String extension;

  @override
  bool operator ==(Object other) =>
      other is ByExtension && other.extension == extension;

  @override
  int get hashCode => Object.hash(ByExtension, extension);

  @override
  String toString() => 'ByExtension($extension)';
}

/// An image whose name looks like a screenshot.
final class ScreenshotName extends ClassificationReason {
  const ScreenshotName();

  @override
  bool operator ==(Object other) => other is ScreenshotName;

  @override
  int get hashCode => (ScreenshotName).hashCode;

  @override
  String toString() => 'ScreenshotName()';
}

/// An image lying directly in a screenshots folder.
final class ScreenshotFolder extends ClassificationReason {
  const ScreenshotFolder();

  @override
  bool operator ==(Object other) => other is ScreenshotFolder;

  @override
  int get hashCode => (ScreenshotFolder).hashCode;

  @override
  String toString() => 'ScreenshotFolder()';
}

/// The AI suggested the category (later stages).
final class AiSuggestion extends ClassificationReason {
  const AiSuggestion();

  @override
  bool operator ==(Object other) => other is AiSuggestion;

  @override
  int get hashCode => (AiSuggestion).hashCode;

  @override
  String toString() => 'AiSuggestion()';
}

/// Unresolved: the extension is not known.
final class UnknownExtension extends ClassificationReason {
  const UnknownExtension(this.extension);

  /// Lower case, without the dot; never empty (see [NoExtension]).
  final String extension;

  @override
  bool operator ==(Object other) =>
      other is UnknownExtension && other.extension == extension;

  @override
  int get hashCode => Object.hash(UnknownExtension, extension);

  @override
  String toString() => 'UnknownExtension($extension)';
}

/// Unresolved: the file has no extension.
final class NoExtension extends ClassificationReason {
  const NoExtension();

  @override
  bool operator ==(Object other) => other is NoExtension;

  @override
  int get hashCode => (NoExtension).hashCode;

  @override
  String toString() => 'NoExtension()';
}

/// Unresolved: a screenshot name on a file that is not an image.
final class ScreenshotNameNotImage extends ClassificationReason {
  const ScreenshotNameNotImage(this.extension);

  /// Lower case, without the dot.
  final String extension;

  @override
  bool operator ==(Object other) =>
      other is ScreenshotNameNotImage && other.extension == extension;

  @override
  int get hashCode => Object.hash(ScreenshotNameNotImage, extension);

  @override
  String toString() => 'ScreenshotNameNotImage($extension)';
}

/// Unresolved: the MIME type points to another media family than the
/// extension.
final class MimeMismatch extends ClassificationReason {
  const MimeMismatch({required this.mimeType, required this.extension});

  final String mimeType;

  /// Lower case, without the dot.
  final String extension;

  @override
  bool operator ==(Object other) =>
      other is MimeMismatch &&
      other.mimeType == mimeType &&
      other.extension == extension;

  @override
  int get hashCode => Object.hash(MimeMismatch, mimeType, extension);

  @override
  String toString() => 'MimeMismatch($mimeType, $extension)';
}
