import 'package:file_organizer/core/ports/clock.dart';

/// The real [Clock]: the system time, in UTC.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
