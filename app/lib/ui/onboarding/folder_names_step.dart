import 'dart:async';

import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/onboarding/folder_name_check.dart';
import 'package:file_organizer/ui/onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The last onboarding step: the folder names of the template, proposed in
/// the language of the phone; the user may change them. They are fixed
/// when confirmed (`docs/stage2_android.md`, 3.3).
class FolderNamesStep extends ConsumerStatefulWidget {
  const FolderNamesStep({required this.saving, super.key});

  /// The confirmed names are being saved.
  final bool saving;

  @override
  ConsumerState<FolderNamesStep> createState() => _FolderNamesStepState();
}

class _FolderNamesStepState extends ConsumerState<FolderNamesStep> {
  late final Map<Category, TextEditingController> _fields = {
    for (final MapEntry(key: category, value: name)
        in ref.read(proposedFolderNamesProvider).entries)
      category: TextEditingController(text: name),
  };

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Map<Category, String> get _names => {
    for (final MapEntry(key: category, value: field) in _fields.entries)
      category: field.text.trim(),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final problems = folderNameProblems(_names);
    return OnboardingPage(
      icon: Icons.create_new_folder_outlined,
      title: l.folderNamesTitle,
      actions: [
        FilledButton(
          onPressed: problems.isEmpty && !widget.saving ? _confirm : null,
          child: widget.saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.folderNamesConfirm),
        ),
      ],
      children: [
        Text(l.folderNamesExplanation),
        const SizedBox(height: 16),
        for (final category in Category.values)
          if (_fields[category] case final field?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                key: ValueKey(category),
                controller: field,
                enabled: !widget.saving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: categoryLabel(l, category),
                  prefixIcon: const Icon(Icons.folder_outlined),
                  border: const OutlineInputBorder(),
                  errorText: switch (problems[category]) {
                    final problem? => folderNameProblemText(l, problem),
                    null => null,
                  },
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
      ],
    );
  }

  void _confirm() {
    unawaited(
      ref.read(appControllerProvider.notifier).confirmFolderNames(_names),
    );
  }
}
