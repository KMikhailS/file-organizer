import 'dart:async';

import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/cleanup_status.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TEMPORARY screen of stage 2, task 10: the start, the access, and a plan
/// without applying it, to check the wiring and the life cycle on a device.
/// Tasks 12–14 replace it with the real screens. Only the access and the
/// folder names (task 11) speak the user's language.
class PlaceholderScreen extends ConsumerStatefulWidget {
  const PlaceholderScreen({super.key});

  @override
  ConsumerState<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends ConsumerState<PlaceholderScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ref.read(appControllerProvider.notifier).start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Access may have been granted in the system settings meanwhile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appControllerProvider.notifier).start());
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('File Organizer (preview)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (app) {
          AppStarting() => const Center(child: CircularProgressIndicator()),
          AccessNeeded() => _AccessNeeded(
            onGrant: () =>
                ref.read(appControllerProvider.notifier).requestAccess(),
          ),
          FolderNamesNeeded() => const _FolderNames(),
          StartupFailed(:final reason) => Text('Could not start: $reason'),
          AppReady() => const _Cleanup(),
        },
      ),
    );
  }
}

class _AccessNeeded extends StatelessWidget {
  const _AccessNeeded({required this.onGrant});

  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.accessNeeded),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => unawaited(onGrant()),
          child: Text(l.grantAccess),
        ),
      ],
    );
  }
}

/// The folder names proposed on the first start, with "Confirm". Editing
/// them comes with the onboarding of task 12.
class _FolderNames extends ConsumerWidget {
  const _FolderNames();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final names = ref.watch(proposedFolderNamesProvider);
    // Built in full (not lazily): eight names fit any phone.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.folderNamesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l.folderNamesExplanation),
          const SizedBox(height: 16),
          for (final category in Category.values)
            if (names[category] case final name?)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(name),
              ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => unawaited(
                ref
                    .read(appControllerProvider.notifier)
                    .confirmFolderNames(names),
              ),
              child: Text(l.folderNamesConfirm),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cleanup extends ConsumerWidget {
  const _Cleanup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cleanupStatusProvider);
    final actions = ref.read(cleanupActionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status.text, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: status.canPlan
                  ? () => unawaited(actions.plan())
                  : null,
              child: const Text('Make a plan'),
            ),
            OutlinedButton(
              onPressed: status.canCancel ? actions.cancel : null,
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: status.canDismiss ? actions.dismiss : null,
              child: const Text('Dismiss plan'),
            ),
          ],
        ),
      ],
    );
  }
}
