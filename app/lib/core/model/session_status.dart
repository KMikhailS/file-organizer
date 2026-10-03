/// Status of a cleanup session.
///
/// Allowed transitions:
///
/// ```
/// planned → running | cancelled
/// running → completed | failed | cancelled
/// completed | failed | cancelled | partiallyReverted
///   → reverted | partiallyReverted
/// reverted is final
/// ```
enum SessionStatus {
  /// The plan is built, nothing executed yet.
  planned,

  /// Operations are being executed (or the app crashed while executing).
  running,

  completed,

  failed,

  /// Stopped by the user. What was done can be undone.
  cancelled,

  /// Every done operation was undone.
  reverted,

  /// Some operations were undone, others were skipped or not undone yet.
  partiallyReverted;

  /// Whether execution has finished; such sessions have a finish time.
  bool get isFinished => this != planned && this != running;

  /// Whether a session in this status may move to [next].
  bool canTransitionTo(SessionStatus next) => switch (this) {
    planned => next == running || next == cancelled,
    running => next == completed || next == failed || next == cancelled,
    completed ||
    failed ||
    cancelled ||
    partiallyReverted => next == reverted || next == partiallyReverted,
    reverted => false,
  };
}
