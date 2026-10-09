import 'dart:async';

import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/cleanup_status.dart';
import 'package:file_organizer/ui/home/last_cleanup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The home screen (`docs/stage2_android.md`, section 9): the big "Tidy up"
/// button, what the last cleanup did, and the access when it was taken
/// back.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(appControllerProvider);
    final ready = status is AppReady;
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (status is AccessNeeded) ...[
              const _AccessRevoked(),
              const SizedBox(height: 24),
            ],
            SizedBox(
              height: 72,
              child: FilledButton.icon(
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(
                  l.cleanUpButton,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                onPressed: ready
                    ? () => unawaited(ref.read(cleanupActionsProvider).plan())
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            const LastCleanupCard(),
          ],
        ),
      ),
    );
  }
}

class _AccessRevoked extends ConsumerWidget {
  const _AccessRevoked();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              l.accessRevokedTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            Text(
              l.accessRevokedText,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            FilledButton(
              onPressed: () => unawaited(
                ref.read(appControllerProvider.notifier).requestAccess(),
              ),
              child: Text(l.grantAccess),
            ),
          ],
        ),
      ),
    );
  }
}
