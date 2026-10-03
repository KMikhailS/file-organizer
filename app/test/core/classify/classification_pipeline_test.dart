import 'package:file_organizer/core/classify/classify.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_classifier.dart';
import '../../support/model_fixtures.dart';

void main() {
  List<ClassificationRequest> requests(List<String> paths) => [
    for (final path in paths)
      ClassificationRequest(file: fileEntry(path), zone: Zone.chaos),
  ];

  test('without AI only the rules run', () async {
    final pipeline = ClassificationPipeline(rules: RuleClassifier());
    final results = await pipeline.classify(requests(['a.pdf', 'b.xyz']));
    expect(results.map((c) => c.category), [
      Category.documents,
      Category.unresolved,
    ]);
  });

  test('AI only sees what the rules left unresolved', () async {
    final ai = FakeClassifier({'b.xyz': Category.documents});
    final pipeline = ClassificationPipeline(rules: RuleClassifier(), ai: ai);

    final results = await pipeline.classify(
      requests(['a.pdf', 'b.xyz', 'c.mp3', 'd.unknown']),
    );

    expect(ai.requests.map((r) => r.file.path.value), ['b.xyz', 'd.unknown']);
    expect(results.map((c) => (c.category, c.origin)), [
      (Category.documents, ClassificationOrigin.rule),
      (Category.documents, ClassificationOrigin.ai),
      (Category.music, ClassificationOrigin.rule),
      (Category.unresolved, ClassificationOrigin.ai),
    ]);
  });

  test('AI is not called when the rules resolve everything', () async {
    final ai = FakeClassifier();
    await ClassificationPipeline(
      rules: RuleClassifier(),
      ai: ai,
    ).classify(requests(['a.pdf']));
    expect(ai.requests, isEmpty);
  });

  test('a classifier returning the wrong number of results is a bug', () {
    expect(
      ClassificationPipeline(rules: _Broken()).classify(requests(['a.pdf'])),
      throwsStateError,
    );
  });
}

final class _Broken implements Classifier {
  @override
  Future<List<Classification>> classify(
    List<ClassificationRequest> requests,
  ) async => const [];
}
