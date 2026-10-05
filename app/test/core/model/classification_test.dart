import 'package:file_organizer/core/model/model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  Classification classification({
    Category category = Category.documents,
    LogicalPath? subfolder,
    double confidence = 0.9,
    ClassificationOrigin origin = ClassificationOrigin.rule,
    ClassificationReason reason = const ByExtension('pdf'),
  }) => Classification(
    category: category,
    subfolder: subfolder,
    confidence: confidence,
    origin: origin,
    reason: reason,
  );

  test('value equality covers every field', () {
    expectValueEquality(classification, {
      'category': classification(category: Category.photos),
      'subfolder': classification(subfolder: p('Taxes')),
      'confidence': classification(confidence: 0.5),
      'origin': classification(origin: ClassificationOrigin.ai),
      'reason': classification(reason: const ScreenshotName()),
    });
  });

  test('accepts confidence bounds', () {
    expect(classification(confidence: 0).confidence, 0);
    expect(classification(confidence: 1).confidence, 1);
  });

  for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
    test('rejects confidence $bad', () {
      expect(() => classification(confidence: bad), throwsArgumentError);
    });
  }

  test('rejects the root as a subfolder', () {
    expect(
      () => classification(subfolder: LogicalPath.root),
      throwsArgumentError,
    );
  });

  test('a subfolder cannot escape the category folder', () {
    // The subfolder is a LogicalPath, so ".." cannot even be constructed.
    expect(
      () => classification(subfolder: p('../Windows')),
      throwsArgumentError,
    );
  });

  test('an unresolved file has no subfolder', () {
    expect(
      () => classification(category: Category.unresolved, subfolder: p('X')),
      throwsArgumentError,
    );
    expect(
      classification(category: Category.unresolved, confidence: 0).category,
      Category.unresolved,
    );
  });
}
