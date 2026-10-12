import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pipeline could not make a plan. Nothing was changed.
class PlanFailedScreen extends ConsumerWidget {
  const PlanFailedScreen({required this.reason, super.key});

  /// Technical, for support; shown small.
  final String reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(l.planFailedTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                l.startupFailedDetails(reason),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ref.read(cleanupActionsProvider).dismiss(),
                child: Text(l.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
