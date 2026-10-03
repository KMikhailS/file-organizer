import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/classification.dart';
import 'package:file_organizer/core/ports/classifier.dart';

/// Rules first; then, if an AI classifier is set, AI for what the rules
/// left [Category.unresolved]. Without AI (stage 1) only the rules run.
final class ClassificationPipeline implements Classifier {
  ClassificationPipeline({required this._rules, this._ai});

  final Classifier _rules;
  final Classifier? _ai;

  @override
  Future<List<Classification>> classify(
    List<ClassificationRequest> requests,
  ) async {
    final results = List.of(await _rules.classify(requests));
    _checkLength(results, requests);
    final ai = _ai;
    if (ai == null) {
      return results;
    }

    final unresolved = [
      for (var i = 0; i < results.length; i++)
        if (results[i].category == Category.unresolved) i,
    ];
    if (unresolved.isEmpty) {
      return results;
    }
    final answers = await ai.classify([
      for (final i in unresolved) requests[i],
    ]);
    _checkLength(answers, unresolved);
    for (var j = 0; j < unresolved.length; j++) {
      results[unresolved[j]] = answers[j];
    }
    return results;
  }

  static void _checkLength(List<Object?> results, List<Object?> requests) {
    if (results.length != requests.length) {
      throw StateError(
        'Classifier returned ${results.length} results for '
        '${requests.length} requests',
      );
    }
  }
}
