import 'package:file_organizer/platform/services/system_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clock = SystemClock();

  test('gives the current time in UTC', () {
    final before = DateTime.now();
    final now = clock.now();
    final after = DateTime.now();
    expect(now.isUtc, isTrue);
    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });

  test('does not go back', () {
    var last = clock.now();
    for (var i = 0; i < 1000; i++) {
      final next = clock.now();
      expect(next.isBefore(last), isFalse);
      last = next;
    }
  });
}
