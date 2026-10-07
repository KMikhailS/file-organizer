import 'dart:async';

/// Lets a caller stop a long read (hashing) that is already running.
///
/// The caller keeps the token and calls [cancel]; the adapter checks
/// [isCancelled] between blocks (or waits for [whenCancelled] when the read
/// runs elsewhere, such as in another isolate) and then returns
/// `FileErrorKind.cancelled`. A token cannot be reset: use a new one for the
/// next run.
final class CancelToken {
  final Completer<void> _cancelled = Completer<void>();

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is called; already complete if it was. Never
  /// completes with an error.
  Future<void> get whenCancelled => _cancelled.future;

  /// Asks every call that got this token to stop as soon as possible.
  /// Calling it again does nothing.
  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }
}
