import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/value_equality.dart';

void main() {
  group('SourceCapabilities', () {
    test('none has every flag off', () {
      const none = SourceCapabilities.none;
      expect([
        none.canMove,
        none.canMkdir,
        none.canQuarantine,
        none.quarantineRestorable,
        none.canAddToAlbum,
        none.providesCapturedAt,
      ], everyElement(isFalse));
    });

    test('value equality covers every flag', () {
      expectValueEquality(
        // Not const on purpose: equality must not rely on canonicalization.
        // ignore: prefer_const_constructors
        () => SourceCapabilities(canMove: true, canMkdir: true),
        {
          'canMove': const SourceCapabilities(canMkdir: true),
          'canMkdir': const SourceCapabilities(canMove: true),
          'canQuarantine': const SourceCapabilities(
            canMove: true,
            canMkdir: true,
            canQuarantine: true,
          ),
          'quarantineRestorable': const SourceCapabilities(
            canMove: true,
            canMkdir: true,
            quarantineRestorable: true,
          ),
          'canAddToAlbum': const SourceCapabilities(
            canMove: true,
            canMkdir: true,
            canAddToAlbum: true,
          ),
          'providesCapturedAt': const SourceCapabilities(
            canMove: true,
            canMkdir: true,
            providesCapturedAt: true,
          ),
          'systemPurgesQuarantine': const SourceCapabilities(
            canMove: true,
            canMkdir: true,
            systemPurgesQuarantine: true,
          ),
        },
      );
    });
  });

  group('Source', () {
    Source source({
      String id = 's1',
      SourceKind kind = SourceKind.desktopFolder,
      String displayName = 'Home',
      String location = '/home/user',
      SourceCapabilities capabilities = const SourceCapabilities(canMove: true),
      bool enabled = true,
    }) => Source(
      id: SourceId(id),
      kind: kind,
      displayName: displayName,
      location: location,
      capabilities: capabilities,
      enabled: enabled,
    );

    test('value equality covers every field', () {
      expectValueEquality(source, {
        'id': source(id: 's2'),
        'kind': source(kind: SourceKind.androidSafTree),
        'displayName': source(displayName: 'Other'),
        'location': source(location: '/storage/emulated/0'),
        'capabilities': source(capabilities: SourceCapabilities.none),
        'enabled': source(enabled: false),
      });
    });
  });
}
