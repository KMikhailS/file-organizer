import 'dart:async';

import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/state/history/history_providers.dart';
import 'package:file_organizer/ui/cleanup/problem_tile.dart';
import 'package:file_organizer/ui/cleanup/undo_confirm.dart';
import 'package:file_organizer/ui/texts/size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How a cleanup or an undo ended (`docs/stage2_android.md`, section 9,
/// screen 5): done, skipped and failed, the problems with their reasons
/// ("needs attention" first), "Undo the cleanup" and "Close".
class ResultScreen extends ConsumerWidget {
  const ResultScreen({required this.result, super.key});

  final CleanupResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final actions = ref.read(cleanupActionsProvider);
    final t = result.totals;
    final undone =
        result.kind == ResultKind.reverted ||
        result.kind == ResultKind.partiallyReverted;
    final title = switch (result.kind) {
      ResultKind.completed => l.resultCompleted,
      ResultKind.cancelled => l.resultCancelled,
      ResultKind.reverted => l.resultReverted,
      ResultKind.partiallyReverted => l.resultPartiallyReverted,
    };
    final counts = [
      if (undone) ...[
        l.countReverted(t.reverted),
        if (t.revertSkipped > 0) l.countNotReverted(t.revertSkipped),
      ] else ...[
        l.countDone(t.done),
        if (t.skipped > 0) l.countSkipped(t.skipped),
        if (t.failed > 0) l.countFailed(t.failed),
        if (t.removedBytes > 0) l.lastCleanupFreed(sizeText(l, t.removedBytes)),
      ],
    ];
    final problems = [
      for (final id in result.sessions)
        ...?ref.watch(sessionProblemsProvider(id)).value,
    ];
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
                    problems.isEmpty
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 48,
                    color: problems.isEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ...counts.map(Text.new),
                  if (problems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(l.problemsTitle, style: theme.textTheme.titleMedium),
                    ...problems.map((p) => ProblemTile(problem: p)),
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
                  if (result.canUndo)
                    OutlinedButton(
                      onPressed: () async {
                        if (await confirmUndo(context)) {
                          unawaited(actions.undoLast());
                        }
                      },
                      child: Text(l.undoCleanupButton),
                    ),
                  FilledButton(
                    onPressed: actions.dismiss,
                    child: Text(l.closeButton),
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
