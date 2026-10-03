import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  ClassificationRule rule({
    String id = 'r',
    Category category = Category.documents,
    int priority = 0,
    Set<String> extensions = const {'pdf'},
    String? nameContains = 'scan',
    LogicalPath? folder,
    SourceId? sourceId = testSource,
  }) => ClassificationRule(
    id: id,
    category: category,
    priority: priority,
    extensions: extensions,
    nameContains: nameContains,
    folder: folder ?? p('Download'),
    sourceId: sourceId,
  );

  test('value equality covers every field', () {
    expectValueEquality(rule, {
      'id': rule(id: 'x'),
      'category': rule(category: Category.other),
      'priority': rule(priority: 1),
      'extensions': rule(extensions: {'pdf', 'doc'}),
      'nameContains': rule(nameContains: 'other'),
      'folder': rule(folder: p('Desktop')),
      'sourceId': rule(sourceId: null),
    });
  });

  test('normalizes extensions and the name text', () {
    final r = rule(extensions: {'.PDF', 'Doc'}, nameContains: 'SCAN');
    expect(r.extensions, {'pdf', 'doc'});
    expect(r.nameContains, 'scan');
    expect(r, rule(extensions: {'pdf', 'doc'}));
  });

  test('needs an id and at least one condition', () {
    expect(() => rule(id: ''), throwsArgumentError);
    expect(
      () => ClassificationRule(id: 'r', category: Category.other),
      throwsArgumentError,
    );
    expect(
      () => ClassificationRule(
        id: 'r',
        category: Category.other,
        nameContains: '',
      ),
      throwsArgumentError,
    );
  });

  group('matches', () {
    test('only when every set condition holds', () {
      final r = rule();
      expect(r.matches(fileEntry('Download/Scan_01.PDF')), isTrue);
      expect(r.matches(fileEntry('Download/sub/my scan.pdf')), isTrue);
      expect(r.matches(fileEntry('Download/Scan_01.doc')), isFalse);
      expect(r.matches(fileEntry('Download/photo.pdf')), isFalse);
      expect(r.matches(fileEntry('Desktop/scan.pdf')), isFalse);
      expect(r.matches(fileEntry('Downloads/scan.pdf')), isFalse);
    });

    test('folders regardless of case', () {
      expect(rule().matches(fileEntry('download/scan.pdf')), isTrue);
    });

    test('the root folder means anywhere', () {
      expect(
        rule(folder: LogicalPath.root).matches(fileEntry('scan.pdf')),
        isTrue,
      );
    });

    test('only files of its source, if it has one', () {
      final other = fileEntry(
        'Download/scan.pdf',
        sourceId: const SourceId('o'),
      );
      expect(rule().matches(other), isFalse);
      expect(rule(sourceId: null).matches(other), isTrue);
    });
  });
}
