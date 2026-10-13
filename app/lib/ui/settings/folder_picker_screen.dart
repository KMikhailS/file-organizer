import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/settings/settings_providers.dart';
import 'package:file_organizer/ui/settings/settings_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chooses a folder of the shared storage, level by level (decision of
/// task 15); pops with the chosen folder. Back goes one level up.
class FolderPickerScreen extends ConsumerStatefulWidget {
  const FolderPickerScreen({super.key});

  /// Opens the picker; the chosen folder, or `null` if the user left.
  static Future<LogicalPath?> pick(BuildContext context) =>
      Navigator.of(context).push<LogicalPath>(
        MaterialPageRoute(builder: (_) => const FolderPickerScreen()),
      );

  @override
  ConsumerState<FolderPickerScreen> createState() => _FolderPickerScreenState();
}

class _FolderPickerScreenState extends ConsumerState<FolderPickerScreen> {
  LogicalPath _folder = LogicalPath.root;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final children = ref.watch(childFoldersProvider(_folder));
    return PopScope(
      canPop: _folder.isRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _folder = _folder.parent ?? LogicalPath.root);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.chooseFolderTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(32),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  folderLabel(l, _folder),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        body: switch (children) {
          AsyncData(value: null) ||
          AsyncError() => Center(child: Text(l.folderUnreadable)),
          AsyncData(value: final names?) when names.isEmpty => Center(
            child: Text(l.noSubfolders),
          ),
          AsyncData(value: final names?) => ListView.builder(
            itemCount: names.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(names[i]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _folder = _folder.child(names[i])),
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_folder),
              child: Text(l.chooseThisFolder),
            ),
          ),
        ),
      ),
    );
  }
}
