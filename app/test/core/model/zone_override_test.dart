import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  ZoneOverride mark({
    SourceId sourceId = testSource,
    String folder = 'Download',
    Zone zone = Zone.chaos,
  }) => ZoneOverride(sourceId: sourceId, folder: p(folder), zone: zone);

  test('value equality covers every field', () {
    expectValueEquality(mark, {
      'sourceId': mark(sourceId: const SourceId('other')),
      'folder': mark(folder: 'Desktop'),
      'zone': mark(zone: Zone.organized),
    });
  });

  test('accepts chaos, organized and excluded', () {
    for (final zone in [Zone.chaos, Zone.organized, Zone.excluded]) {
      expect(mark(zone: zone).zone, zone);
    }
  });

  test('rejects target: target folders come from the template', () {
    expect(() => mark(zone: Zone.target), throwsArgumentError);
  });
}
