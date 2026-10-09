import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/session_status.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/last_cleanup.dart';
import 'package:file_organizer/ui/texts/date_text.dart';
import 'package:file_organizer/ui/texts/size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the last cleanup did, on the home screen.
class LastCleanupCard extends ConsumerWidget {
  const LastCleanupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(lastCleanupProvider).value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: session == null
            ? Text(l.lastCleanupNone, style: theme.textTheme.bodyLarge)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    l.lastCleanupTitle(
                      dateText(l, session.finishedAt ?? session.startedAt),
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(sessionStatusText(l, session.status)),
                  ..._counts(l, session).map(Text.new),
                ],
              ),
      ),
    );
  }

  static List<String> _counts(AppLocalizations l, CleanupSession session) {
    final stats = session.stats;
    final problems = stats.failed + stats.skipped;
    final undone = stats.reverted + stats.revertSkipped;
    return [
      l.lastCleanupDone(stats.done + undone, stats.total),
      if (problems > 0) l.lastCleanupProblems(problems),
      if (stats.reverted > 0) l.lastCleanupReverted(stats.reverted),
      if (stats.removedBytes > 0)
        l.lastCleanupFreed(sizeText(l, stats.removedBytes)),
    ];
  }
}

/// The status of a finished cleanup in the user's language.
String sessionStatusText(AppLocalizations l, SessionStatus status) =>
    switch (status) {
      SessionStatus.completed => l.sessionCompleted,
      SessionStatus.failed => l.sessionFailed,
      SessionStatus.cancelled => l.sessionCancelled,
      SessionStatus.reverted => l.sessionReverted,
      SessionStatus.partiallyReverted => l.sessionPartiallyReverted,
      // Not finished: never the last cleanup.
      SessionStatus.planned || SessionStatus.running => '',
    };
