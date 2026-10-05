import 'dart:math';

import 'package:file_organizer/platform/services/random_id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives 0, 1, 2, ... so the bytes of an id are known.
final class _CountingRandom implements Random {
  int _next = 0;

  @override
  int nextInt(int max) => _next++ % max;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  test('formats 16 random bytes as a version 4 UUID', () {
    final ids = RandomIdGenerator(random: _CountingRandom());
    // Bytes 00..0f; byte 6 (06) gets version 4, byte 8 (08) the variant.
    expect(ids.newId(), '00010203-0405-4607-8809-0a0b0c0d0e0f');
    // Bytes 10..1f: the version and variant bits replace the old ones.
    expect(ids.newId(), '10111213-1415-4617-9819-1a1b1c1d1e1f');
  });

  test('sets version and variant whatever the random bytes are', () {
    final ids = RandomIdGenerator(random: Random(7));
    for (var i = 0; i < 1000; i++) {
      expect(ids.newId(), matches(_uuidV4));
    }
  });

  test('the default generator gives distinct valid ids', () {
    final ids = RandomIdGenerator();
    final seen = <String>{};
    for (var i = 0; i < 10000; i++) {
      final id = ids.newId();
      expect(id, matches(_uuidV4));
      expect(seen.add(id), isTrue, reason: 'duplicate $id');
    }
  });
}
