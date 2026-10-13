import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/session_status.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/state/cleanup/cleanup_view_of.dart';
import 'package:file_organizer/state/history/history_view.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read again whenever the workflow moves to another kind of state (a
/// cleanup or an undo ended), so the history shows what it changed.
void _followWorkflow(Ref ref) => ref.watch(
  workflowStateProvider.select((state) => state.value?.runtimeType),
);

/// Every cleanup that was executed, newest first.
final historyProvider = FutureProvider<List<CleanupSession>>((ref) async {
  _followWorkflow(ref);
  final sessions = await ref.watch(repositoriesProvider).sessions.all();
  return [
    for (final session in sessions)
      if (session.status != SessionStatus.planned) session,
  ];
});

/// One cleanup with its groups and files, from the journal.
final sessionDetailProvider = FutureProvider.autoDispose
    .family<SessionDetail?, SessionId>((ref, id) async {
      _followWorkflow(ref);
      final repositories = ref.watch(repositoriesProvider);
      final session = await repositories.sessions.byId(id);
      if (session == null) {
        return null;
      }
      final operations = await repositories.journal.bySession(id);
      final byGroup = <String, List<HistoryFile>>{};
      for (final op in operations) {
        // Folders follow the files moved into them.
        if (op.type == OperationType.mkdir) {
          continue;
        }
        (byGroup[op.groupKey] ??= []).add(
          HistoryFile(
            operationId: op.id,
            type: op.type,
            from: op.fromPath!,
            to: op.type == OperationType.move ? op.toPath : null,
            status: op.status,
            problem: op.error,
          ),
        );
      }
      return SessionDetail(
        session: session,
        groups: [
          for (final MapEntry(:key, :value) in byGroup.entries)
            HistoryGroup(key: key, kind: groupKind(key), files: value),
        ],
      );
    });

/// The problems of a session (failed, skipped, not undone), "needs
/// attention" first, for the result screen.
final sessionProblemsProvider = FutureProvider.autoDispose
    .family<List<ProblemView>, SessionId>((ref, id) async {
      _followWorkflow(ref);
      return problemsOf(
        await ref.watch(repositoriesProvider).journal.bySession(id),
      );
    });
