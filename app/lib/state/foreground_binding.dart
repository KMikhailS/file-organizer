import 'dart:async';

import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/state/app_texts.dart';

/// Keeps the foreground service in step with the workflow (decision A.7,
/// `docs/stage2_android.md`, section 5.3): it runs while the workflow scans,
/// analyzes, executes or undoes, its notification shows the progress, and
/// it stops in every other state. When the system stops it for its time
/// limit, the running work is cancelled.
final class ForegroundBinding {
  ForegroundBinding({
    required this._native,
    required this._workflow,
    required this._texts,
  });

  final AndroidNative _native;
  final CleanupWorkflow _workflow;

  /// The texts in the current language.
  final AppTexts Function() _texts;
  StreamSubscription<WorkflowState>? _states;
  StreamSubscription<void>? _timeouts;
  bool _running = false;

  /// Starts following the workflow. Calling it again does nothing.
  void attach() {
    _states ??= _workflow.states.listen(_follow);
    _timeouts ??= _native.foregroundTimeouts.listen((_) => _workflow.cancel());
  }

  Future<void> dispose() async {
    await _states?.cancel();
    await _timeouts?.cancel();
    _states = null;
    _timeouts = null;
  }

  void _follow(WorkflowState state) {
    final notice = noticeFor(state, _texts());
    // The calls go over one channel in order; nothing waits for them.
    if (notice == null) {
      if (_running) {
        _running = false;
        unawaited(_native.stopForeground());
      }
    } else if (_running) {
      unawaited(_native.updateForeground(notice));
    } else {
      _running = true;
      unawaited(_native.startForeground(notice));
    }
  }

  /// What the notification shows in [state], or `null` if the service
  /// should not run.
  static ForegroundNotice? noticeFor(WorkflowState state, AppTexts texts) {
    ForegroundNotice notice(String title, String text, int done, int total) =>
        ForegroundNotice(
          title: title,
          text: text,
          channelName: texts.channelName,
          done: done,
          total: total,
        );
    return switch (state) {
      Scanning(:final filesProcessed) => notice(
        texts.scanning,
        texts.filesSeen(filesProcessed),
        0,
        0,
      ),
      Analyzing(:final sizesDone, :final sizesTotal) => notice(
        texts.analyzing,
        texts.stepOf(sizesDone, sizesTotal),
        sizesDone,
        sizesTotal,
      ),
      Executing(:final progress) => notice(
        texts.executing,
        progress == null ? '' : texts.stepOf(progress.done, progress.total),
        progress?.done ?? 0,
        progress?.total ?? 0,
      ),
      Undoing(:final operationsProcessed) => notice(
        texts.undoing,
        texts.filesSeen(operationsProcessed),
        0,
        0,
      ),
      Idle() || Interrupted() || PlanReady() || Finished() || Failed() => null,
    };
  }
}
