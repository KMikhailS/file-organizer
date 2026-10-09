import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/l10n/app_localizations.dart';

/// What is wrong with a folder name the user typed.
enum FolderNameProblem {
  empty,
  tooLong,
  forbiddenCharacter,
  leadingDot,
  duplicate,
}

/// The longest folder name the app accepts.
const int maxFolderNameLength = 64;

/// Characters a folder name cannot contain: `/` separates folders, the
/// others are not allowed by Windows and by FAT storage, so the names stay
/// usable on every platform (control characters are not allowed either).
const String forbiddenFolderNameCharacters = r'/\:*?"<>|';

/// The problems of the folder names [names] (already trimmed), per
/// category; empty when the template can use them.
///
/// Stricter than `checkLayoutFolderNames` of the core (which the
/// confirmation runs as well): names that pass here always pass there.
Map<Category, FolderNameProblem> folderNameProblems(
  Map<Category, String> names,
) {
  final problems = <Category, FolderNameProblem>{};
  final seen = <String>{};
  for (final category in Category.values) {
    if (category == Category.unresolved) {
      continue;
    }
    final name = names[category] ?? '';
    final problem = _problemWith(name);
    if (problem != null) {
      problems[category] = problem;
    } else if (!seen.add(name.toLowerCase())) {
      problems[category] = FolderNameProblem.duplicate;
    }
  }
  return problems;
}

FolderNameProblem? _problemWith(String name) {
  if (name.isEmpty) {
    return FolderNameProblem.empty;
  }
  if (name.length > maxFolderNameLength) {
    return FolderNameProblem.tooLong;
  }
  if (name.startsWith('.')) {
    return FolderNameProblem.leadingDot;
  }
  if (name.runes.any(
        (c) =>
            c < 0x20 ||
            c == 0x7f ||
            forbiddenFolderNameCharacters.runes.contains(c),
      ) ||
      LogicalPath.problemWith(name) != null) {
    return FolderNameProblem.forbiddenCharacter;
  }
  return null;
}

/// The message for [problem] in the user's language.
String folderNameProblemText(AppLocalizations l, FolderNameProblem problem) =>
    switch (problem) {
      FolderNameProblem.empty => l.folderNameEmpty,
      FolderNameProblem.tooLong => l.folderNameTooLong(maxFolderNameLength),
      FolderNameProblem.forbiddenCharacter => l.folderNameForbidden(
        forbiddenFolderNameCharacters.split('').join(' '),
      ),
      FolderNameProblem.leadingDot => l.folderNameLeadingDot,
      FolderNameProblem.duplicate => l.folderNameDuplicate,
    };

/// What a folder name field is for, in the user's language.
String categoryLabel(AppLocalizations l, Category category) =>
    switch (category) {
      Category.documents => l.categoryDocuments,
      Category.photos => l.categoryPhotos,
      Category.videos => l.categoryVideos,
      Category.screenshots => l.categoryScreenshots,
      Category.music => l.categoryMusic,
      Category.archives => l.categoryArchives,
      Category.installers => l.categoryInstallers,
      Category.other => l.categoryOther,
      // Unresolved files stay where they are: no folder, no field.
      Category.unresolved => '',
    };
