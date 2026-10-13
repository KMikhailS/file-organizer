import 'dart:typed_data';

import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/core/undo/undo_types.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/state/cleanup/cleanup_view_of.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Cancel" was asked for (on a screen or in the notification) and the
/// work has not stopped yet. Cleared when the workflow is not busy any
/// more.
final class CancelRequest extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(workflowStateProvider, (_, next) {
      if (!(next.value?.isBusy ?? false)) {
        state = false;
      }
    });
    return false;
  }

  void requested() => state = true;
}

final cancelRequestProvider = NotifierProvider<CancelRequest, bool>(
  CancelRequest.new,
);

/// What the cleanup screens show now.
final cleanupViewProvider = Provider<CleanupView>(
  (ref) => cleanupViewOf(
    ref.watch(workflowStateProvider).value,
    cancelling: ref.watch(cancelRequestProvider),
  ),
);

/// The commands of the cleanup screens.
final class CleanupActions {
  const CleanupActions(this._ref);

  final Ref _ref;

  /// Scans and plans.
  Future<void> plan() => _ref.read(workflowProvider).start();

  void setGroupApproval(
    SourceId source,
    String groupKey, {
    required bool approved,
  }) => _ref
      .read(workflowProvider)
      .setGroupApproval(source, groupKey, approved: approved);

  void setFileApproval(
    SourceId source,
    int operationIndex, {
    required bool approved,
  }) => _ref
      .read(workflowProvider)
      .setOperationApproval(source, operationIndex, approved: approved);

  /// Executes the approved operations.
  Future<void> apply() => _ref.read(workflowProvider).execute();

  /// Undoes the last run (the result on screen) or the interrupted
  /// sessions.
  Future<void> undoLast() => _ref.read(workflowProvider).undo();

  /// Undoes a past cleanup from the history: all of it, one of its groups
  /// ([groupKey]) or one file ([operationId]).
  Future<void> undoSession(
    SessionId session, {
    String? groupKey,
    OperationId? operationId,
  }) => _ref
      .read(workflowProvider)
      .undoSession(
        session,
        scope: switch ((groupKey, operationId)) {
          (_, final OperationId id) => OneOperation(id),
          (final String key, null) => OneGroup(key),
          (null, null) => const WholeSession(),
        },
      );

  /// Declines the plan, closes a result or a failure, or leaves an
  /// interrupted cleanup for later.
  void dismiss() => _ref.read(workflowProvider).dismiss();

  /// Stops what runs: scanning and analysis at once, execution and undo
  /// after the current operation. Does nothing when nothing runs.
  void cancel() {
    final workflow = _ref.read(workflowProvider);
    if (!workflow.state.isBusy) {
      return;
    }
    _ref.read(cancelRequestProvider.notifier).requested();
    workflow.cancel();
  }
}

final cleanupActionsProvider = Provider<CleanupActions>(CleanupActions.new);

/// The longest edge of a thumbnail in the plan, in pixels.
const int thumbnailSize = 192;

/// The thumbnail of a photo or video in the plan, or `null` if the system
/// has none. Dropped when no screen shows it.
final thumbnailProvider = FutureProvider.autoDispose
    .family<Uint8List?, (Source, LogicalPath)>(
      (ref, file) => ref
          .read(appServicesProvider)
          .thumbnail(file.$1, file.$2, thumbnailSize),
    );
