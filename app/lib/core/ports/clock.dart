/// Source of the current time. The core never calls `DateTime.now()`.
abstract interface class Clock {
  /// The current time, in UTC.
  DateTime now();
}
