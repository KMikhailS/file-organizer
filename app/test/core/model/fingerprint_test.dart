import 'package:file_organizer/core/model/fingerprint.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  test('value equality covers every field', () {
    expectValueEquality(() => fingerprint(hash: 'h'), {
      'size': fingerprint(size: 1, hash: 'h'),
      'modifiedAt': fingerprint(
        modifiedAt: testTime.add(const Duration(microseconds: 1)),
        hash: 'h',
      ),
      'fullHash': fingerprint(hash: 'other'),
      'no fullHash': fingerprint(),
    });
  });

  test('stores modifiedAt in UTC, so equal instants compare equal', () {
    final local = testTime.toLocal();
    final fromLocal = Fingerprint(size: 1, modifiedAt: local);
    expect(fromLocal.modifiedAt.isUtc, isTrue);
    expect(fromLocal, Fingerprint(size: 1, modifiedAt: testTime));
  });

  test('rejects a negative size', () {
    expect(
      () => Fingerprint(size: -1, modifiedAt: testTime),
      throwsArgumentError,
    );
  });

  test('accepts a zero size', () {
    expect(Fingerprint(size: 0, modifiedAt: testTime).size, 0);
  });
}
