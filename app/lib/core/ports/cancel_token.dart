/// Lets a caller stop a long read (hashing) that is already running.
///
/// The caller keeps the token and calls [cancel]; the adapter checks
/// [isCancelled] between blocks and then returns `FileErrorKind.cancelled`.
/// A token cannot be reset: use a new one for the next run.
final class CancelToken {
  bool _cancelled = false;

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled;

  /// Asks every call that got this token to stop as soon as possible.
  void cancel() => _cancelled = true;
}
