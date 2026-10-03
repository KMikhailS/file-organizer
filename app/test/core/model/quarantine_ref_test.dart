import 'package:file_organizer/core/model/quarantine_ref.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/value_equality.dart';

void main() {
  test('value equality', () {
    expectValueEquality(() => QuarantineRef('q/1'), {
      'value': QuarantineRef('q/2'),
    });
  });

  test('rejects an empty reference', () {
    expect(() => QuarantineRef(''), throwsArgumentError);
  });
}
