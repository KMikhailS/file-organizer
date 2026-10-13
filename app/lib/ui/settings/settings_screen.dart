import 'dart:async';

import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:file_organizer/core/model/zone_override.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/notification_permission.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/state/settings/settings_providers.dart';
import 'package:file_organizer/ui/settings/folder_picker_screen.dart';
import 'package:file_organizer/ui/settings/rule_editor_screen.dart';
import 'package:file_organizer/ui/settings/settings_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The settings (`docs/stage2_android.md`, section 9, screen 8 and 5.23):
/// folder marks, the user's rules, the quarantine retention, the language
/// and the permissions. Every change is saved at once.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          _ZoneMarks(),
          Divider(height: 32),
          _Rules(),
          Divider(height: 32),
          _Quarantine(),
          Divider(height: 32),
          _Language(),
          Divider(height: 32),
          _Permissions(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, [this.hint]);

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (hint != null) Text(hint!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ZoneMarks extends ConsumerWidget {
  const _ZoneMarks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final marks = ref.watch(zoneMarksProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(l.sectionFolders, l.foldersHint),
        if (marks.isEmpty)
          ListTile(title: Text(l.noFolderMarks))
        else
          for (final mark in marks)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(folderLabel(l, mark.folder)),
              subtitle: Text(zoneText(l, mark.zone)),
              onTap: () => unawaited(_choose(context, ref, mark.folder, mark)),
              trailing: IconButton(
                tooltip: l.removeMark,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => unawaited(
                  ref.read(zoneMarksProvider.notifier).unmark(mark.folder),
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.addFolderMark),
            onPressed: () async {
              final folder = await FolderPickerScreen.pick(context);
              if (folder != null && context.mounted) {
                await _choose(context, ref, folder, null);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Asks what to do with [folder]; "Tidy up" asks again with a warning.
  static Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    LogicalPath folder,
    ZoneOverride? current,
  ) async {
    final l = AppLocalizations.of(context);
    // Files in template folders never move (safety invariant 6): a mark
    // there does nothing, and the user should know.
    final templateFolders = {
      for (final name in (ref.read(layoutFolderNamesProvider) ?? {}).values)
        name.toLowerCase(),
    };
    final inTemplate =
        !folder.isRoot &&
        templateFolders.contains(folder.segments.first.toLowerCase());
    final zone = await showDialog<Zone>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.chooseZoneTitle(folderLabel(l, folder))),
        children: [
          if (inTemplate)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(l.templateFolderNote),
            ),
          for (final zone in [Zone.chaos, Zone.organized, Zone.excluded])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(zone),
              child: ListTile(
                selected: current?.zone == zone,
                title: Text(zoneText(l, zone)),
                subtitle: Text(zoneHint(l, zone)),
              ),
            ),
        ],
      ),
    );
    if (zone == null || !context.mounted) {
      return;
    }
    if (zone == Zone.chaos) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l.chaosWarning(folderLabel(l, folder))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.continueButton),
            ),
          ],
        ),
      );
      if (sure != true) {
        return;
      }
    }
    await ref.read(zoneMarksProvider.notifier).mark(folder, zone);
  }
}

class _Rules extends ConsumerWidget {
  const _Rules();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rules = ref.watch(userRulesProvider).value ?? const [];
    final folderNames = ref.watch(layoutFolderNamesProvider) ?? const {};
    final notifier = ref.read(userRulesProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(l.sectionRules, l.rulesHint),
        if (rules.isEmpty)
          ListTile(title: Text(l.noRules))
        else
          for (final (i, rule) in rules.indexed)
            ListTile(
              title: Text(ruleSummaryText(l, rule, folderNames)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RuleEditorScreen(rule: rule),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.moveUp,
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: i == 0
                        ? null
                        : () => unawaited(notifier.move(rule.id, up: true)),
                  ),
                  IconButton(
                    tooltip: l.moveDown,
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: i == rules.length - 1
                        ? null
                        : () => unawaited(notifier.move(rule.id, up: false)),
                  ),
                  IconButton(
                    tooltip: l.deleteButton,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => unawaited(notifier.remove(rule.id)),
                  ),
                ],
              ),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.addRule),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RuleEditorScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _Quarantine extends ConsumerWidget {
  const _Quarantine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(settingsProvider).value?.quarantineRetention;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(l.sectionQuarantine, l.quarantineHint),
        RadioGroup<Duration>(
          groupValue: current,
          onChanged: (retention) async {
            if (retention == null || current == null || retention == current) {
              return;
            }
            if (retention < current) {
              final sure = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(l.retentionShorterWarning(retention.inDays)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l.continueButton),
                    ),
                  ],
                ),
              );
              if (sure != true) {
                return;
              }
            }
            await ref
                .read(settingsProvider.notifier)
                .setQuarantineRetention(retention);
          },
          child: Column(
            children: [
              for (final retention in quarantineRetentions)
                RadioListTile<Duration>(
                  value: retention,
                  title: Text(l.retentionDays(retention.inDays)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Language extends ConsumerWidget {
  const _Language();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value;
    String label(String? language) => switch (language) {
      'ru' => l.languageRu,
      'en' => l.languageEn,
      _ => l.languageSystem,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(l.sectionLanguage),
        RadioGroup<String>(
          // The system language is the empty value of the group.
          groupValue: settings == null ? null : settings.uiLocale ?? '',
          onChanged: (value) => unawaited(
            ref
                .read(settingsProvider.notifier)
                .setUiLocale(value == null || value.isEmpty ? null : value),
          ),
          child: Column(
            children: [
              for (final language in uiLanguages)
                RadioListTile<String>(
                  value: language ?? '',
                  title: Text(label(language)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Permissions extends ConsumerWidget {
  const _Permissions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final access = ref.watch(appControllerProvider) is! AccessNeeded;
    final notifications =
        ref.watch(notificationPermissionProvider).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(l.sectionPermissions),
        ListTile(
          title: Text(l.permissionAllFiles),
          subtitle: Text(access ? l.permissionGranted : l.permissionNotGranted),
          trailing: access
              ? const Icon(Icons.check)
              : TextButton(
                  onPressed: () => unawaited(
                    ref.read(appControllerProvider.notifier).requestAccess(),
                  ),
                  child: Text(l.grantAccess),
                ),
        ),
        ListTile(
          title: Text(l.notificationsTitle),
          subtitle: Text(
            notifications ? l.notificationsOn : l.notificationsOff,
          ),
          trailing: notifications
              ? const Icon(Icons.check)
              : TextButton(
                  onPressed: () => unawaited(
                    ref.read(notificationPermissionProvider.notifier).request(),
                  ),
                  child: Text(l.allowNotifications),
                ),
        ),
      ],
    );
  }
}
