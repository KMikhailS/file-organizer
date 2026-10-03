import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/classifier.dart';

/// A classifier with canned answers by path; everything else is
/// [Category.unresolved]. Records every request.
class FakeClassifier implements Classifier {
  FakeClassifier([Map<String, Category> byPath = const {}])
    : _byPath = Map.of(byPath);

  final Map<String, Category> _byPath;

  /// Every request received, in order.
  final List<ClassificationRequest> requests = [];

  /// Makes the file at [path] classify as [category].
  void answer(String path, Category category) => _byPath[path] = category;

  @override
  Future<List<Classification>> classify(
    List<ClassificationRequest> requests,
  ) async {
    this.requests.addAll(requests);
    return [
      for (final request in requests)
        switch (_byPath[request.file.path.value]) {
          final category? => Classification(
            category: category,
            confidence: 1,
            origin: ClassificationOrigin.ai,
            reason: 'fake answer',
          ),
          null => Classification(
            category: Category.unresolved,
            confidence: 0,
            origin: ClassificationOrigin.ai,
            reason: 'fake: no answer',
          ),
        },
    ];
  }
}
