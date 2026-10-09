import 'package:file_organizer/core/model/cleanup_session.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The newest cleanup session that finished executing (completed, failed,
/// cancelled or undone), or `null` if there is none yet. Read again when
/// the workflow moves to another kind of state (a cleanup or an undo ends).
final lastCleanupProvider = FutureProvider<CleanupSession?>((ref) async {
  ref.watch(workflowStateProvider.select((state) => state.value?.runtimeType));
  final sessions = await ref.watch(repositoriesProvider).sessions.all();
  for (final session in sessions) {
    if (session.status.isFinished) {
      return session;
    }
  }
  return null;
});
