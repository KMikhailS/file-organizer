import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/planner/planning.dart';
import 'package:file_organizer/core/zones/zones.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/model_fixtures.dart';

void main() {
  PlanValidator validator({
    SourceCapabilities capabilities = desktopCapabilities,
    Set<String> targets = const {'Документы'},
  }) => PlanValidator(
    sourceId: testSource,
    capabilities: capabilities,
    zones: ZoneMap(
      sourceId: testSource,
      config: ZoneConfig(targetFolders: {for (final t in targets) p(t)}),
    ),
    existingPaths: [
      for (final path in [
        'Download',
        'Download/a.pdf',
        'Download/b.pdf',
        'Download/.hidden.pdf',
        'Документы',
        'Документы/x.pdf',
        'Documents',
        'Documents/c.pdf',
      ])
        p(path),
    ],
    existingFolders: [p('Download'), p('Документы'), p('Documents')],
  );

  List<ViolationKind> kinds(List<PlannedOperation> ops, {PlanValidator? v}) =>
      (v ?? validator())
          .validate(Plan(operations: ops))
          .map((x) => x.kind)
          .toList();

  test('a valid plan has no violations', () {
    expect(
      kinds([
        plannedQuarantine('Download/b.pdf'),
        plannedMkdir('Документы/sub'),
        plannedMove('Download/a.pdf', 'Документы/sub/a.pdf'),
        plannedMove('Download/a (2).pdf', 'Документы/a.pdf'),
      ]),
      isEmpty,
    );
  });

  group('overwrite', () {
    test('a move onto an existing file', () {
      expect(kinds([plannedMove('Download/a.pdf', 'Документы/x.pdf')]), [
        ViolationKind.overwrite,
      ]);
    });

    test('regardless of case', () {
      expect(kinds([plannedMove('Download/a.pdf', 'документы/X.PDF')]), [
        ViolationKind.overwrite,
      ]);
    });

    test('a mkdir of an existing folder', () {
      expect(kinds([plannedMkdir('Документы')]), [ViolationKind.overwrite]);
    });
  });

  test('two operations with one target', () {
    expect(
      kinds([
        plannedMove('Download/a.pdf', 'Документы/n.pdf'),
        plannedMove('Download/b.pdf', 'Документы/N.pdf'),
      ]),
      [ViolationKind.duplicateTarget],
    );
  });

  test('one file in two operations', () {
    expect(
      kinds([
        plannedQuarantine('Download/a.pdf'),
        plannedMove('Download/a.pdf', 'Документы/a.pdf'),
      ]),
      [ViolationKind.fileUsedTwice],
    );
  });

  test('case variants of a source path are different files', () {
    expect(
      kinds([
        plannedMove('Download/a.pdf', 'Документы/a.pdf'),
        plannedMove('Download/A.pdf', 'Документы/A (2).pdf'),
      ]),
      isEmpty,
    );
  });

  test('an operation of another source', () {
    final foreign = PlannedOperation.quarantine(
      sourceId: const SourceId('other'),
      path: p('Download/a.pdf'),
      fingerprint: fingerprint(),
      reason: 'r',
      groupKey: 'g',
      approved: true,
    );
    expect(kinds([foreign]), [ViolationKind.leavesSource]);
  });

  group('protected zones', () {
    test('taking a file from an organized folder', () {
      expect(kinds([plannedQuarantine('Documents/c.pdf')]), [
        ViolationKind.protectedZone,
      ]);
      expect(kinds([plannedMove('Documents/c.pdf', 'Документы/c.pdf')]), [
        ViolationKind.protectedZone,
      ]);
    });

    test('taking a file from a target folder', () {
      expect(kinds([plannedQuarantine('Документы/x.pdf')]), [
        ViolationKind.protectedZone,
      ]);
    });

    test('taking an excluded file', () {
      expect(kinds([plannedQuarantine('Download/.hidden.pdf')]), [
        ViolationKind.protectedZone,
      ]);
    });

    test('putting a file outside the target folders', () {
      expect(kinds([plannedMove('Download/a.pdf', 'Documents/a.pdf')]), [
        ViolationKind.protectedZone,
      ]);
      expect(kinds([plannedMove('Download/a.pdf', 'Download/z.pdf')]), [
        ViolationKind.protectedZone,
      ]);
    });

    test('creating a folder outside the template', () {
      expect(kinds([plannedMkdir('Documents/new')]), [
        ViolationKind.protectedZone,
      ]);
    });

    test('a folder on the way to a template folder may be created', () {
      final nested = validator(targets: {'Sorted/Документы'});
      expect(
        kinds([
          plannedMkdir('Sorted'),
          plannedMkdir('Sorted/Документы'),
        ], v: nested),
        isEmpty,
      );
      expect(kinds([plannedMkdir('Elsewhere')], v: nested), [
        ViolationKind.protectedZone,
      ]);
    });
  });

  test('operations the source cannot do', () {
    final ios = validator(capabilities: iosPhotosCapabilities);
    expect(
      kinds([
        plannedMkdir('Документы/a'),
        plannedMove('Download/a.pdf', 'Документы/a/a.pdf'),
        plannedQuarantine('Download/b.pdf'),
      ], v: ios),
      [
        ViolationKind.unsupported,
        ViolationKind.unsupported,
        ViolationKind.unsupported,
      ],
    );
  });

  group('missing parents', () {
    test('a move into a folder that is neither there nor created', () {
      expect(kinds([plannedMove('Download/a.pdf', 'Документы/sub/a.pdf')]), [
        ViolationKind.missingParent,
      ]);
    });

    test('a folder created after it is needed', () {
      expect(
        kinds([
          plannedMove('Download/a.pdf', 'Документы/sub/a.pdf'),
          plannedMkdir('Документы/sub'),
        ]),
        [ViolationKind.missingParent],
      );
    });

    test('a folder whose parent is missing', () {
      expect(kinds([plannedMkdir('Документы/a/b')]), [
        ViolationKind.missingParent,
      ]);
    });
  });

  test('reports every violation with its operation', () {
    final bad = plannedMove('Documents/c.pdf', 'Documents/x/c.pdf');
    final violations = validator().validate(Plan(operations: [bad]));
    expect(violations.map((v) => v.kind), [
      ViolationKind.protectedZone,
      ViolationKind.protectedZone,
      ViolationKind.missingParent,
    ]);
    expect(violations.map((v) => v.operation), everyElement(bad));
  });
}
