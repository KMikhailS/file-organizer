import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/reason_fixtures.dart';

/// Every value of [build] equals a second build; all values differ from each
/// other. Lists one value per class and per parameter.
void expectCodes<T extends Object>(List<T> Function() build) {
  final a = build();
  final b = build();
  for (var i = 0; i < a.length; i++) {
    expect(a[i], b[i], reason: '${a[i]} equals itself');
    expect(a[i].hashCode, b[i].hashCode, reason: '${a[i]} hash');
    for (var j = 0; j < a.length; j++) {
      if (i != j) {
        expect(a[i], isNot(a[j]), reason: '${a[i]} vs ${a[j]}');
      }
    }
  }
}

void main() {
  test('classification reasons: value equality, every code distinct', () {
    expectCodes(classificationReasons);
  });

  test('operation reasons: value equality, every code distinct', () {
    expectCodes(operationReasons);
  });

  test('operation problems: value equality, every code distinct', () {
    expectCodes(operationProblems);
  });

  test('codes with different classes but equal parameters differ', () {
    expect(KeeperChanged(path('a')), isNot(DependsOnMissingFolder(path('a'))));
    expect(const LegacyReason('x'), isNot(const LegacyProblem('x')));
    expect(const ByExtension('pdf'), isNot(const UnknownExtension('pdf')));
  });
}
