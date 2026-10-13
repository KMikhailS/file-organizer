import 'dart:async';

import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation_status.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/state/history/history_providers.dart';
import 'package:file_organizer/state/history/history_view.dart';
import 'package:file_organizer/ui/cleanup/plan_texts.dart';
import 'package:file_organizer/ui/cleanup/undo_confirm.dart';
import 'package:file_organizer/ui/texts/date_text.dart';
import 'package:file_organizer/ui/texts/path_text.dart';
import 'package:file_organizer/ui/texts/problem_texts.dart';
import 'package:file_organizer/ui/texts/session_status_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One past cleanup: its groups and files with their status; undo of the
/// whole cleanup, a group or a file. Files whose quarantine was emptied are
/// marked and cannot come back. Starting an undo closes the history: the
/// progress and the result follow on the main screens.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({required this.sessionId, super.key});

  final SessionId sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(sessionDetailProvider(sessionId)).value;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final session = detail.session;
    Future<void> undo({String? groupKey, OperationId? operationId}) async {
      final actions = ref.read(cleanupActionsProvider);
      Navigator.of(context).popUntil((route) => route.isFirst);
      await actions.undoSession(
        sessionId,
        groupKey: groupKey,
        operationId: operationId,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.sessionTitle(dateText(l, session.finishedAt ?? session.startedAt)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            title: Text(sessionStatusText(l, session.status)),
            subtitle: detail.purged > 0 ? Text(l.purgedMark) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: detail.undoable == 0
                ? Text(l.nothingToUndo)
                : OutlinedButton(
                    onPressed: () async {
                      if (await confirmUndo(context, files: detail.undoable)) {
                        unawaited(undo());
                      }
                    },
                    child: Text(l.undoWholeButton),
                  ),
          ),
          for (final group in detail.groups) ...[
            const Divider(height: 32),
            ListTile(
              title: Text(_groupTitle(l, group)),
              subtitle: Text(l.groupFiles(group.files.length)),
              trailing: group.undoable == 0
                  ? null
                  : TextButton(
                      onPressed: () async {
                        if (await confirmUndo(context, files: group.undoable)) {
                          unawaited(undo(groupKey: group.key));
                        }
                      },
                      child: Text(l.undoGroupButton),
                    ),
            ),
            for (final file in group.files)
              _FileTile(
                file: file,
                onUndo: () => unawaited(undo(operationId: file.operationId)),
              ),
          ],
        ],
      ),
    );
  }

  static String _groupTitle(AppLocalizations l, HistoryGroup group) =>
      switch (group.kind) {
        DuplicatesGroup() => l.groupDuplicatesTitle,
        MoveGroup(:final folder) => l.groupMoveTitle(folderText(folder)),
      };
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.onUndo});

  final HistoryFile file;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = file.purged
        ? l.purgedMark
        : switch (file.status) {
            OperationStatus.done => l.fileDone,
            OperationStatus.reverted => l.fileReverted,
            _ =>
              file.problem == null
                  ? ''
                  : operationProblemText(l, file.problem!),
          };
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ListTile(
        title: Text(fileName(file.from), overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [pathText(file.from), status].where((s) => s.isNotEmpty).join('\n'),
          style: file.purged ? TextStyle(color: theme.colorScheme.error) : null,
        ),
        isThreeLine: true,
        trailing: file.undoable
            ? TextButton(onPressed: onUndo, child: Text(l.undoFileButton))
            : null,
      ),
    );
  }
}
