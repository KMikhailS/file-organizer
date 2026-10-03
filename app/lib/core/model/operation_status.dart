/// Status of a journal operation.
///
/// Allowed transitions:
///
/// ```
/// pending → done | failed | skipped
/// done → reverted | revertSkipped
/// revertSkipped → reverted | revertSkipped (undo retried)
/// failed, skipped and reverted are final
/// ```
enum OperationStatus {
  /// Written to the journal, not executed yet (or interrupted).
  pending,

  /// Executed successfully.
  done,

  /// Execution failed.
  failed,

  /// Not executed: the file changed since planning, or an operation it
  /// depends on failed.
  skipped,

  /// Undone.
  reverted,

  /// Undo was not possible (file missing or changed, quarantine purged).
  revertSkipped;

  /// Whether an operation in this status may move to [next].
  bool canTransitionTo(OperationStatus next) => switch (this) {
    pending => next == done || next == failed || next == skipped,
    done => next == reverted || next == revertSkipped,
    revertSkipped => next == reverted || next == revertSkipped,
    failed || skipped || reverted => false,
  };

  /// Whether an operation in this status carries an error description.
  bool get hasError =>
      this == failed || this == skipped || this == revertSkipped;
}
