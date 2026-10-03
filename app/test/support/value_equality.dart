import 'package:flutter_test/flutter_test.dart';

/// Checks value equality of a domain model.
///
/// [create] must build a fresh instance with the same values on every call.
/// Each of [variants] must differ from it in exactly one field; listing one
/// variant per field proves that every field takes part in `==`.
void expectValueEquality<T extends Object>(
  T Function() create,
  Map<String, T> variants,
) {
  final a = create();
  final b = create();
  expect(identical(a, b), isFalse, reason: 'create must build new instances');
  expect(a, equals(b));
  expect(a.hashCode, b.hashCode);

  for (final MapEntry(key: field, value: variant) in variants.entries) {
    expect(variant, isNot(equals(a)), reason: 'differs in $field');
    expect(a, isNot(equals(variant)), reason: 'differs in $field');
  }
}
