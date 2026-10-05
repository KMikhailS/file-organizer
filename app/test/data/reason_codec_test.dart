import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/data/repositories/reason_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/reason_fixtures.dart';

void main() {
  group('round trip', () {
    test('every operation reason, with every classification reason', () {
      for (final reason in [
        ...operationReasons(),
        for (final r in classificationReasons()) Classified(r),
      ]) {
        expect(
          decodeOperationReason(encodeOperationReason(reason)),
          reason,
          reason: '$reason',
        );
      }
    });

    test('every operation problem', () {
      for (final problem in operationProblems()) {
        expect(
          decodeOperationProblem(encodeOperationProblem(problem)),
          problem,
          reason: '$problem',
        );
      }
    });
  });

  test('the stored format is stable JSON with a code', () {
    expect(
      encodeOperationReason(DuplicateOf(LogicalPath('Download/a.pdf'))),
      '{"code":"duplicateOf","keeper":"Download/a.pdf"}',
    );
    expect(
      encodeOperationReason(const Classified(ByExtension('pdf'))),
      '{"code":"classified","reason":{"code":"byExtension","extension":"pdf"}}',
    );
    expect(
      encodeOperationProblem(const FileSystemError(FileErrorKind.locked)),
      '{"code":"fileSystem","kind":"locked"}',
    );
    expect(
      encodeOperationProblem(
        const NeedsAttention(
          AttentionCause.cannotCheck,
          errorKind: FileErrorKind.permissionDenied,
        ),
      ),
      '{"code":"needsAttention","cause":"cannotCheck",'
      '"kind":"permissionDenied"}',
    );
    expect(
      encodeOperationProblem(const InterruptedOperation()),
      '{"code":"interrupted"}',
    );
  });

  group('text that is not a known code is kept as legacy', () {
    final stored = <String, String>{
      'free text of schema version 1': 'duplicate of Download/a.pdf',
      'the legacy code written by the migration':
          '{"code":"legacy","text":"file is gone"}',
      'not a JSON object': '["fileGone"]',
      'broken JSON': '{"code":',
      'a code of a newer app version': '{"code":"somethingNew"}',
      'a known code with a missing parameter': '{"code":"duplicateOf"}',
      'an unknown file error kind': '{"code":"fileSystem","kind":"melted"}',
      'an unknown attention cause': '{"code":"needsAttention","cause":"x"}',
    };
    for (final MapEntry(key: name, value: text) in stored.entries) {
      test(name, () {
        final legacyText = text.startsWith('{"code":"legacy"')
            ? 'file is gone'
            : text;
        expect(decodeOperationReason(text), LegacyReason(legacyText));
        expect(decodeOperationProblem(text), LegacyProblem(legacyText));
      });
    }
  });
}
