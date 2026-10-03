import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  group('factories set the fields of their type', () {
    test('mkdir', () {
      final op = plannedMkdir('Documents');
      expect(op.type, OperationType.mkdir);
      expect(op.fromPath, isNull);
      expect(op.toPath, p('Documents'));
      expect(op.fingerprint, isNull);
    });

    test('move', () {
      final op = plannedMove('Download/a.pdf', 'Documents/a.pdf');
      expect(op.type, OperationType.move);
      expect(op.fromPath, p('Download/a.pdf'));
      expect(op.toPath, p('Documents/a.pdf'));
      expect(op.fingerprint, fingerprint());
    });

    test('quarantine', () {
      final op = plannedQuarantine('Download/a (1).pdf');
      expect(op.type, OperationType.quarantine);
      expect(op.fromPath, p('Download/a (1).pdf'));
      expect(op.toPath, isNull);
      expect(op.fingerprint, fingerprint());
    });

    test('addToAlbum', () {
      final op = PlannedOperation.addToAlbum(
        sourceId: testSource,
        path: p('IMG_1.HEIC'),
        fingerprint: fingerprint(),
        reason: 'duplicate',
        groupKey: 'duplicates',
        approved: true,
      );
      expect(op.type, OperationType.addToAlbum);
      expect(op.fromPath, p('IMG_1.HEIC'));
      expect(op.toPath, isNull);
    });
  });

  group('rejects', () {
    test('mkdir of the source root', () {
      expect(() => plannedMkdir(''), throwsArgumentError);
    });

    test('a move that does not change the path', () {
      expect(() => plannedMove('a.pdf', 'a.pdf'), throwsArgumentError);
    });

    test('a move from or to the source root', () {
      expect(() => plannedMove('', 'a.pdf'), throwsArgumentError);
      expect(() => plannedMove('a.pdf', ''), throwsArgumentError);
    });

    test('a move into itself', () {
      expect(() => plannedMove('dir', 'dir/sub'), throwsArgumentError);
    });

    test('quarantine of the source root', () {
      expect(() => plannedQuarantine(''), throwsArgumentError);
    });
  });

  group('OperationType.checkShape', () {
    final f = fingerprint();
    final a = p('a');
    final b = p('b');
    const invalid = <String, (OperationType, bool, bool, bool)>{
      // (type, has fromPath, has toPath, has fingerprint)
      'mkdir with fromPath': (OperationType.mkdir, true, true, false),
      'mkdir without toPath': (OperationType.mkdir, false, false, false),
      'mkdir with fingerprint': (OperationType.mkdir, false, true, true),
      'move without fromPath': (OperationType.move, false, true, true),
      'move without toPath': (OperationType.move, true, false, true),
      'move without fingerprint': (OperationType.move, true, true, false),
      'quarantine with toPath': (OperationType.quarantine, true, true, true),
      'quarantine without fromPath': (
        OperationType.quarantine,
        false,
        false,
        true,
      ),
      'quarantine without fingerprint': (
        OperationType.quarantine,
        true,
        false,
        false,
      ),
      'addToAlbum with toPath': (OperationType.addToAlbum, true, true, true),
      'addToAlbum without fingerprint': (
        OperationType.addToAlbum,
        true,
        false,
        false,
      ),
    };
    for (final MapEntry(key: name, value: (type, from, to, fp))
        in invalid.entries) {
      test('rejects $name', () {
        expect(
          () => type.checkShape(
            fromPath: from ? a : null,
            toPath: to ? b : null,
            fingerprint: fp ? f : null,
          ),
          throwsArgumentError,
        );
      });
    }

    test('flags', () {
      expect(OperationType.mkdir.actsOnFile, isFalse);
      expect(OperationType.move.actsOnFile, isTrue);
      expect(OperationType.move.removesFile, isFalse);
      expect(OperationType.quarantine.removesFile, isTrue);
      expect(OperationType.addToAlbum.removesFile, isTrue);
    });
  });

  test('value equality covers every field', () {
    PlannedOperation move({
      SourceId sourceId = testSource,
      String from = 'a.pdf',
      String to = 'Documents/a.pdf',
      Fingerprint? fp,
      String reason = 'r',
      String groupKey = 'g',
      bool approved = true,
    }) => PlannedOperation.move(
      sourceId: sourceId,
      from: p(from),
      to: p(to),
      fingerprint: fp ?? fingerprint(),
      reason: reason,
      groupKey: groupKey,
      approved: approved,
    );

    expectValueEquality(move, {
      'type': plannedQuarantine('a.pdf', groupKey: 'g'),
      'sourceId': move(sourceId: const SourceId('other')),
      'fromPath': move(from: 'b.pdf'),
      'toPath': move(to: 'Documents/b.pdf'),
      'fingerprint': move(fp: fingerprint(size: 1)),
      'reason': move(reason: 'other'),
      'groupKey': move(groupKey: 'other'),
      'approved': move(approved: false),
    });
  });

  test('withApproved changes only the approval', () {
    final op = plannedMove('a.pdf', 'b.pdf');
    final declined = op.withApproved(approved: false);
    expect(declined.approved, isFalse);
    expect(declined.withApproved(approved: true), op);
  });
}
