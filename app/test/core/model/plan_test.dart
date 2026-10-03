import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  final mkdir = plannedMkdir('Documents', groupKey: 'documents');
  final move1 = plannedMove('a.pdf', 'Documents/a.pdf', groupKey: 'documents');
  final dup1 = plannedQuarantine('a (1).pdf', size: 300);
  final move2 = plannedMove(
    'b.pdf',
    'Documents/b.pdf',
    groupKey: 'documents',
    approved: false,
    size: 7,
  );
  final dup2 = plannedQuarantine('b (1).pdf', size: 40, approved: false);

  Plan plan() => Plan(
    operations: [mkdir, move1, dup1, move2, dup2],
    unresolved: [fileEntry('mystery.xyz')],
  );

  test('value equality covers every field', () {
    expectValueEquality(plan, {
      'operations': Plan(
        operations: [mkdir, move1, dup1, move2],
        unresolved: [fileEntry('mystery.xyz')],
      ),
      'operation order': Plan(
        operations: [move1, mkdir, dup1, move2, dup2],
        unresolved: [fileEntry('mystery.xyz')],
      ),
      'unresolved': Plan(operations: [mkdir, move1, dup1, move2, dup2]),
      'duplicateGroups': Plan(
        operations: [mkdir, move1, dup1, move2, dup2],
        unresolved: [fileEntry('mystery.xyz')],
        duplicateGroups: [
          DuplicateGroup(
            fullHash: 'h',
            files: [
              fileEntry('x', fullHash: 'h'),
              fileEntry('y', fullHash: 'h'),
            ],
            keeper: fileEntry('x', fullHash: 'h'),
            keeperReason: KeeperReason.alphabeticalPath,
          ),
        ],
      ),
    });
  });

  test('lists are unmodifiable', () {
    expect(() => plan().operations.add(mkdir), throwsUnsupportedError);
    expect(() => plan().unresolved.clear(), throwsUnsupportedError);
    expect(() => plan().duplicateGroups.clear(), throwsUnsupportedError);
  });

  test('does not share the caller list', () {
    final source = [mkdir];
    final p = Plan(operations: source);
    source.add(move1);
    expect(p.operations, [mkdir]);
  });

  test('groups by key in order of first appearance, keeping order', () {
    final groups = plan().groups;
    expect(groups.map((g) => g.key), ['documents', 'duplicates']);
    expect(groups[0].operations, [mkdir, move1, move2]);
    expect(groups[1].operations, [dup1, dup2]);
  });

  test('summary counts files and reclaimable bytes', () {
    expect(
      plan().summary,
      const PlanSummary(fileCount: 4, reclaimableBytes: 340),
    );
    expect(
      plan().approvedSummary,
      const PlanSummary(fileCount: 2, reclaimableBytes: 300),
    );
    expect(plan().approvedOperations, [mkdir, move1, dup1]);
  });

  test('a group has its own summary', () {
    expect(
      plan().groups[1].summary,
      const PlanSummary(fileCount: 2, reclaimableBytes: 340),
    );
  });

  test('empty means no operations, even with unresolved files', () {
    expect(Plan.empty.isEmpty, isTrue);
    expect(Plan.empty.summary, PlanSummary.zero);
    expect(
      Plan(operations: const [], unresolved: [fileEntry('x.xyz')]).isEmpty,
      isTrue,
    );
    expect(plan().isEmpty, isFalse);
  });

  group('PlanGroup', () {
    test('rejects an empty group', () {
      expect(
        () => PlanGroup(key: 'k', operations: const []),
        throwsArgumentError,
      );
    });

    test('rejects operations of another group', () {
      expect(
        () => PlanGroup(key: 'documents', operations: [move1, dup1]),
        throwsArgumentError,
      );
    });

    test('value equality covers every field', () {
      expectValueEquality(
        () => PlanGroup(key: 'documents', operations: [mkdir, move1]),
        {
          'operations': PlanGroup(key: 'documents', operations: [mkdir]),
          'key': PlanGroup(key: 'duplicates', operations: [dup1]),
        },
      );
    });
  });

  test('PlanSummary value equality covers every field', () {
    expectValueEquality(
      // Not const on purpose: equality must not rely on canonicalization.
      // ignore: prefer_const_constructors
      () => PlanSummary(fileCount: 1, reclaimableBytes: 2),
      {
        'fileCount': const PlanSummary(fileCount: 2, reclaimableBytes: 2),
        'reclaimableBytes': const PlanSummary(
          fileCount: 1,
          reclaimableBytes: 3,
        ),
      },
    );
  });
}
