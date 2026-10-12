import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What runs now (`docs/stage2_android.md`, section 9, screen 3): the
/// stage, its counters and "Cancel". The notification shows the same.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({required this.progress, super.key});

  final InProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = progress;
    final title = switch (p.stage) {
      ProgressStage.scanning => l.progressScanning,
      ProgressStage.analyzing => l.progressAnalyzing,
      ProgressStage.executing => l.progressExecuting,
      ProgressStage.undoing => l.progressUndoing,
    };
    final counter = switch (p.stage) {
      ProgressStage.scanning || ProgressStage.undoing => l.filesCount(p.done),
      ProgressStage.analyzing ||
      ProgressStage.executing => p.total == 0 ? '' : l.stepOf(p.done, p.total),
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: p.total == 0 ? null : p.done / p.total,
              ),
              const SizedBox(height: 12),
              if (counter.isNotEmpty) Text(counter),
              if (p.sourceCount > 1)
                Text(l.progressStorageOf(p.sourceIndex + 1, p.sourceCount)),
              const SizedBox(height: 24),
              Text(l.progressCanLeave, style: theme.textTheme.bodySmall),
              const Spacer(),
              OutlinedButton(
                onPressed: p.cancelling
                    ? null
                    : () => ref.read(cleanupActionsProvider).cancel(),
                child: Text(p.cancelling ? l.cancelling : l.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
