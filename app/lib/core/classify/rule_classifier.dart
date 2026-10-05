import 'package:file_organizer/core/classify/builtin_rules.dart';
import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/classification.dart';
import 'package:file_organizer/core/model/classification_reason.dart';
import 'package:file_organizer/core/model/classification_rule.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/ports/classifier.dart';

/// Classifies files by rules, without AI.
///
/// 1. User rules, in the given order; the first match wins.
/// 2. Screenshots: an image whose name starts with "Screenshot", "Screen
///    Shot", "Снимок экрана" or "Скриншот", or that lies in a
///    `Screenshots` / `Скриншоты` folder.
/// 3. The extension (see [BuiltinRules]).
///
/// Unknown extensions and contradicting signs give [Category.unresolved]:
/// a screenshot name on a non-image, or a MIME type that disagrees with the
/// extension.
final class RuleClassifier implements Classifier {
  /// [userRules] must be in the order they apply (as returned by
  /// `RuleRepository.classificationRules`).
  RuleClassifier({Iterable<ClassificationRule> userRules = const []})
    : _userRules = List.unmodifiable(userRules);

  final List<ClassificationRule> _userRules;

  @override
  Future<List<Classification>> classify(
    List<ClassificationRequest> requests,
  ) async => [for (final request in requests) classifyFile(request.file)];

  /// Classifies one file synchronously.
  Classification classifyFile(FileEntry file) {
    for (final rule in _userRules) {
      if (rule.matches(file)) {
        return _result(rule.category, ByUserRule(rule.id));
      }
    }

    final ext = file.extension;
    final name = file.name.toLowerCase();
    final screenshotName = BuiltinRules.screenshotNamePrefixes.any(
      name.startsWith,
    );
    final isImage = BuiltinRules.screenshotExtensions.contains(ext);

    if (screenshotName && !isImage) {
      return _unresolved(ScreenshotNameNotImage(ext));
    }
    final byExtension = BuiltinRules.categoryOf(ext);
    if (byExtension == null) {
      return _unresolved(
        ext.isEmpty ? const NoExtension() : UnknownExtension(ext),
      );
    }
    if (file.mimeType case final mime? when _contradicts(mime, byExtension)) {
      return _unresolved(MimeMismatch(mimeType: mime, extension: ext));
    }
    if (isImage && screenshotName) {
      return _result(Category.screenshots, const ScreenshotName());
    }
    final folder = file.path.parent!.name.toLowerCase();
    if (isImage && BuiltinRules.screenshotFolders.contains(folder)) {
      return _result(Category.screenshots, const ScreenshotFolder());
    }
    return _result(byExtension, ByExtension(ext));
  }

  /// Whether [mime] and the extension's [category] point to different media
  /// families (image, video, audio). Generic types never contradict.
  static bool _contradicts(String mime, Category category) {
    final lower = mime.toLowerCase();
    if (BuiltinRules.genericMimeTypes.contains(lower)) {
      return false;
    }
    final mimeFamily = BuiltinRules.mimeFamilies.entries
        .where((e) => lower.startsWith(e.key))
        .firstOrNull;
    final extensionFamily = BuiltinRules.mimeFamilies.entries
        .where((e) => e.value.contains(category))
        .firstOrNull;
    return mimeFamily?.key != extensionFamily?.key;
  }

  static Classification _result(
    Category category,
    ClassificationReason reason,
  ) => Classification(
    category: category,
    confidence: category == Category.unresolved ? 0 : 1,
    origin: ClassificationOrigin.rule,
    reason: reason,
  );

  static Classification _unresolved(ClassificationReason reason) =>
      _result(Category.unresolved, reason);
}
