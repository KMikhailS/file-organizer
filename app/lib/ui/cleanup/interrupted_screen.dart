import 'dart:async';

import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/ui/cleanup/problem_tile.dart';
import 'package:file_organizer/ui/cleanup/undo_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A cleanup a crash interrupted, found at start-up (`docs/stage2_android.md`,
/// section 9, screen 6): what recovery sorted out, then "Finish the
/// cleanup", "Undo it" or "Not now" (decision of task 14: the session stays
/// in the history).
class InterruptedScreen extends ConsumerWidget {
  const InterruptedScreen({required this.interrupted, super.key});

  final InterruptedCleanup interrupted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final actions = ref.read(cleanupActionsProvider);
    final i = interrupted;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.interruptedTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(l.interruptedText),
                  const SizedBox(height: 8),
                  if (i.operations > 0)
                    Text(l.interruptedOperations(i.operations)),
                  if (i.unavailable > 0)
                    Text(l.interruptedUnavailable(i.unavailable)),
                  if (i.problems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(l.problemsTitle, style: theme.textTheme.titleMedium),
                    ...i.problems.map((p) => ProblemTile(problem: p)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => unawaited(actions.plan()),
                    child: Text(l.interruptedFinish),
                  ),
                  if (i.sessions > 0)
                    OutlinedButton(
                      onPressed: () async {
                        if (await confirmUndo(context)) {
                          unawaited(actions.undoLast());
                        }
                      },
                      child: Text(l.interruptedUndo),
                    ),
                  TextButton(
                    onPressed: actions.dismiss,
                    child: Text(l.interruptedLater),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
