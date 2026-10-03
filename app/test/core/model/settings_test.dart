import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/value_equality.dart';

void main() {
  test('defaults to 30 days of quarantine', () {
    expect(Settings().quarantineRetention, const Duration(days: 30));
  });

  test('value equality', () {
    expectValueEquality(
      () => Settings(quarantineRetention: const Duration(days: 7)),
      {'quarantineRetention': Settings()},
    );
  });

  test('keeps the quarantine at least a day', () {
    expect(
      () => Settings(quarantineRetention: const Duration(hours: 23)),
      throwsArgumentError,
    );
    expect(
      Settings(quarantineRetention: const Duration(days: 1))
          .quarantineRetention,
      const Duration(days: 1),
    );
  });
}
