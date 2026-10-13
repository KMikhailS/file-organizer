import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/classification_rule.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/state/settings/settings_providers.dart';
import 'package:file_organizer/ui/settings/folder_picker_screen.dart';
import 'package:file_organizer/ui/settings/settings_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adds or changes a rule: extensions, "name contains", a folder, and where
/// matching files go (a template folder, or "Leave where it is"). A rule
/// needs at least one condition.
class RuleEditorScreen extends ConsumerStatefulWidget {
  const RuleEditorScreen({this.rule, super.key});

  /// The rule to change; `null` adds a new one.
  final ClassificationRule? rule;

  @override
  ConsumerState<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends ConsumerState<RuleEditorScreen> {
  late final TextEditingController _extensions = TextEditingController(
    text: ([...?widget.rule?.extensions]..sort()).join(', '),
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.rule?.nameContains ?? '',
  );
  late LogicalPath? _folder = widget.rule?.folder;
  late Category _category = widget.rule?.category ?? Category.documents;
  bool _saving = false;

  @override
  void dispose() {
    _extensions.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _hasCondition =>
      parseExtensions(_extensions.text).isNotEmpty ||
      _name.text.trim().isNotEmpty ||
      _folder != null;

  Future<void> _save() async {
    setState(() => _saving = true);
    final rules = ref.read(userRulesProvider.notifier);
    final name = _name.text.trim();
    await rules.save(
      ClassificationRule(
        id: widget.rule?.id ?? rules.newId(),
        category: _category,
        priority: widget.rule?.priority ?? 0,
        extensions: parseExtensions(_extensions.text),
        nameContains: name.isEmpty ? null : name,
        folder: _folder,
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final folderNames = ref.watch(layoutFolderNamesProvider) ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text(l.ruleTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const ValueKey('extensions'),
            controller: _extensions,
            decoration: InputDecoration(
              labelText: l.ruleExtensions,
              hintText: l.ruleExtensionsHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('name'),
            controller: _name,
            decoration: InputDecoration(
              labelText: l.ruleNameContains,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_outlined),
            title: Text(l.ruleFolder),
            subtitle: Text(
              _folder == null ? l.ruleAnyFolder : folderLabel(l, _folder!),
            ),
            trailing: _folder == null
                ? null
                : IconButton(
                    tooltip: l.ruleAnyFolder,
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _folder = null),
                  ),
            onTap: () async {
              final picked = await FolderPickerScreen.pick(context);
              if (picked != null) {
                setState(() => _folder = picked);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category>(
            key: const ValueKey('target'),
            initialValue: _category,
            decoration: InputDecoration(
              labelText: l.ruleTarget,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final category in Category.values)
                DropdownMenuItem(
                  value: category,
                  child: Text(ruleTargetText(l, category, folderNames)),
                ),
            ],
            onChanged: (category) =>
                setState(() => _category = category ?? _category),
          ),
          if (!_hasCondition) ...[
            const SizedBox(height: 16),
            Text(
              l.ruleNeedsCondition,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _hasCondition && !_saving ? _save : null,
            child: Text(l.saveButton),
          ),
        ),
      ),
    );
  }
}
