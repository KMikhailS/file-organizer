import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/classification_rule.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/cleanup/plan_texts.dart';

/// A folder of the storage as the settings show it; the root is "The whole
/// storage".
String folderLabel(AppLocalizations l, LogicalPath folder) =>
    folder.isRoot ? l.storageRoot : folderText(folder);

/// The name of a zone mark.
String zoneText(AppLocalizations l, Zone zone) => switch (zone) {
  Zone.chaos => l.zoneChaos,
  Zone.organized => l.zoneOrganized,
  Zone.excluded => l.zoneExcluded,
  // Never a mark: target folders come from the template.
  Zone.target => '',
};

/// What a zone mark does.
String zoneHint(AppLocalizations l, Zone zone) => switch (zone) {
  Zone.chaos => l.zoneChaosHint,
  Zone.organized => l.zoneOrganizedHint,
  Zone.excluded => l.zoneExcludedHint,
  Zone.target => '',
};

/// Where a rule puts files: the user's template folder, or "Leave where it
/// is" for [Category.unresolved].
String ruleTargetText(
  AppLocalizations l,
  Category category,
  Map<Category, String> folderNames,
) => category == Category.unresolved
    ? l.ruleKeepInPlace
    : folderNames[category] ?? category.name;

/// A rule in one line: `.pdf, .docx, name contains «scan» → Documents`.
String ruleSummaryText(
  AppLocalizations l,
  ClassificationRule rule,
  Map<Category, String> folderNames,
) {
  final conditions = [
    if (rule.extensions.isNotEmpty)
      ([...rule.extensions]..sort()).map((e) => '.$e').join(', '),
    if (rule.nameContains case final text? when text.isNotEmpty)
      l.ruleSummaryName(text),
    if (rule.folder case final folder?)
      l.ruleSummaryFolder(folderLabel(l, folder)),
  ].join(', ');
  return l.ruleSummary(
    conditions,
    ruleTargetText(l, rule.category, folderNames),
  );
}

/// The extensions typed by the user: separated by commas or spaces, dots
/// and case do not matter.
Set<String> parseExtensions(String text) => {
  for (final part in text.split(RegExp(r'[\s,;]+')))
    if (part.replaceAll('.', '').trim() case final e when e.isNotEmpty)
      e.toLowerCase(),
};
