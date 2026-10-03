import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_classifier.dart';
import 'fake_clock.dart';
import 'model_fixtures.dart';
import 'sequential_id_generator.dart';

void main() {
  group('FakeClock', () {
    test('stands still until advanced', () {
      final clock = FakeClock(start: DateTime.utc(2024));
      expect(clock.now(), DateTime.utc(2024));
      expect(clock.now(), DateTime.utc(2024));
      clock.advance(const Duration(hours: 2));
      expect(clock.now(), DateTime.utc(2024, 1, 1, 2));
      clock.set(DateTime.utc(2030));
      expect(clock.now(), DateTime.utc(2030));
    });

    test('auto-advances after each reading', () {
      final clock = FakeClock(
        start: DateTime.utc(2024),
        autoAdvance: const Duration(seconds: 1),
      );
      expect(
        [clock.now(), clock.now()],
        [DateTime.utc(2024), DateTime.utc(2024, 1, 1, 0, 0, 1)],
      );
    });

    test('always returns UTC and refuses to go back', () {
      final clock = FakeClock(start: DateTime(2024));
      expect(clock.now().isUtc, isTrue);
      expect(
        () => clock.advance(const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });
  });

  test('SequentialIdGenerator is predictable', () {
    final ids = SequentialIdGenerator('op');
    expect([ids.newId(), ids.newId(), ids.newId()], ['op-1', 'op-2', 'op-3']);
  });

  test('FakeClassifier answers by path and records requests', () async {
    final classifier = FakeClassifier({'a.pdf': Category.documents})
      ..answer('b.jpg', Category.photos);
    final requests = [
      ClassificationRequest(file: fileEntry('b.jpg'), zone: Zone.chaos),
      ClassificationRequest(file: fileEntry('a.pdf'), zone: Zone.chaos),
      ClassificationRequest(file: fileEntry('c.xyz'), zone: Zone.chaos),
    ];
    final results = await classifier.classify(requests);
    expect(results.map((c) => c.category), [
      Category.photos,
      Category.documents,
      Category.unresolved,
    ]);
    expect(classifier.requests, requests);
  });
}
