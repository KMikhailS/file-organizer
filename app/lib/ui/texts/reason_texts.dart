import 'package:file_organizer/core/model/classification_reason.dart';
import 'package:file_organizer/core/model/operation_reason.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/texts/path_text.dart';

/// Why the plan has an operation, in the user's language.
String operationReasonText(AppLocalizations l, OperationReason reason) =>
    switch (reason) {
      Classified(:final reason) => classificationReasonText(l, reason),
      DuplicateOf(:final keeper) => l.reasonDuplicateOf(pathText(keeper)),
      FolderFor(:final folder) => l.reasonFolderFor(pathText(folder)),
      MovePlaceholder(:final file) => l.reasonMovePlaceholder(pathText(file)),
      // Written before reasons had codes (database version 1).
      LegacyReason(:final text) => text,
    };

/// Why a file got its category, or why it stays unresolved.
String classificationReasonText(
  AppLocalizations l,
  ClassificationReason reason,
) => switch (reason) {
  ByUserRule() => l.classifiedByUserRule,
  ByExtension(:final extension) => l.classifiedByExtension(extension),
  ScreenshotName() => l.classifiedScreenshotName,
  ScreenshotFolder() => l.classifiedScreenshotFolder,
  AiSuggestion() => l.classifiedAiSuggestion,
  UnknownExtension(:final extension) => l.unresolvedUnknownExtension(extension),
  NoExtension() => l.unresolvedNoExtension,
  ScreenshotNameNotImage(:final extension) =>
    l.unresolvedScreenshotNameNotImage(extension),
  MimeMismatch(:final mimeType, :final extension) => l.unresolvedMimeMismatch(
    mimeType,
    extension,
  ),
};
