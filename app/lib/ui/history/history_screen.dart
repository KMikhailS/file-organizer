import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/history/history_providers.dart';
import 'package:file_organizer/ui/history/session_screen.dart';
import 'package:file_organizer/ui/texts/date_text.dart';
import 'package:file_organizer/ui/texts/session_status_text.dart';
import 'package:file_organizer/ui/texts/size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every cleanup with its status (`docs/stage2_android.md`, section 9,
/// screen 7); a cleanup opens with its groups and files.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sessions = ref.watch(historyProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.historyTitle)),
      body: switch (sessions) {
        null => const Center(child: CircularProgressIndicator()),
        [] => Center(child: Text(l.lastCleanupNone)),
        _ => ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, i) {
            final session = sessions[i];
            final stats = session.stats;
            return ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: Text(dateText(l, session.finishedAt ?? session.startedAt)),
              subtitle: Text(
                [
                  sessionStatusText(l, session.status),
                  l.countDone(
                    stats.done + stats.reverted + stats.revertSkipped,
                  ),
                  if (stats.removedBytes > 0)
                    l.lastCleanupFreed(sizeText(l, stats.removedBytes)),
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionScreen(sessionId: session.id),
                ),
              ),
            );
          },
        ),
      },
    );
  }
}
