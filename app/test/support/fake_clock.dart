import 'package:file_organizer/core/ports/clock.dart';

/// A clock that only moves when told to.
class FakeClock implements Clock {
  /// Starts at [start] (UTC). With [autoAdvance], every [now] call moves the
  /// clock forward afterwards, so consecutive timestamps differ.
  FakeClock({DateTime? start, this.autoAdvance = Duration.zero})
    : _now = (start ?? DateTime.utc(2024, 5, 17, 10, 30)).toUtc();

  final Duration autoAdvance;

  DateTime _now;

  @override
  DateTime now() {
    final current = _now;
    _now = _now.add(autoAdvance);
    return current;
  }

  /// Moves the clock forward by [duration].
  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'must not be negative');
    }
    _now = _now.add(duration);
  }

  /// Sets the clock to [time].
  void set(DateTime time) => _now = time.toUtc();
}
