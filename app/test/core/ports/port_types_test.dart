import 'dart:async';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';
import '../../support/value_equality.dart';

void main() {
  group('FileResult', () {
    test('success and failure are told apart by pattern matching', () {
      String describe(FileResult<int> result) => switch (result) {
        FileSuccess(:final value) => 'ok $value',
        FileFailure(:final error) => 'error ${error.kind.name}',
      };
      expect(describe(const FileSuccess(3)), 'ok 3');
      expect(
        describe(FileFailure.of(FileErrorKind.targetExists)),
        'error targetExists',
      );
    });

    test('isSuccess and errorKind', () {
      expect(succeeded.isSuccess, isTrue);
      expect(succeeded.errorKind, isNull);
      final failure = FileFailure<void>.of(FileErrorKind.locked, 'in use');
      expect(failure.isSuccess, isFalse);
      expect(failure.errorKind, FileErrorKind.locked);
      expect(failure.error.message, 'in use');
    });

    test('value equality', () {
      expectValueEquality(() => FileSuccess<String>('h'.toUpperCase()), {
        'value': const FileSuccess<String>('X'),
      });
      expectValueEquality(
        () => FileFailure<void>.of(FileErrorKind.notFound, 'm'),
        {
          'kind': FileFailure<void>.of(FileErrorKind.ioError, 'm'),
          'message': FileFailure<void>.of(FileErrorKind.notFound),
        },
      );
    });
  });

  test('FileStat value equality and UTC', () {
    FileStat stat({
      FileKind kind = FileKind.file,
      int size = 1,
      DateTime? modifiedAt,
    }) => FileStat(kind: kind, size: size, modifiedAt: modifiedAt ?? testTime);

    expectValueEquality(stat, {
      'kind': stat(kind: FileKind.directory),
      'size': stat(size: 2),
      'modifiedAt': stat(modifiedAt: DateTime.utc(2000)),
    });
    expect(stat(modifiedAt: testTime.toLocal()), stat());
    expect(stat().isFile, isTrue);
    expect(stat(kind: FileKind.directory).isDirectory, isTrue);
  });

  test('FileListPage value equality and unmodifiable lists', () {
    FileListPage page({
      List<String> files = const ['a', 'b'],
      List<String> inaccessible = const ['x'],
      String cursor = 'b',
    }) => FileListPage(
      entries: files.map(fileEntry),
      inaccessible: inaccessible.map(LogicalPath.new),
      cursor: ScanCursor(cursor),
    );

    expectValueEquality(page, {
      'entries': page(files: ['a']),
      'inaccessible': page(inaccessible: []),
      'cursor': page(cursor: 'c'),
    });
    expect(() => page().entries.clear(), throwsUnsupportedError);
    expect(() => page().inaccessible.clear(), throwsUnsupportedError);
  });

  test('ClassificationRequest value equality', () {
    expectValueEquality(
      () => ClassificationRequest(file: fileEntry('a.pdf'), zone: Zone.chaos),
      {
        'file': ClassificationRequest(
          file: fileEntry('b.pdf'),
          zone: Zone.chaos,
        ),
        'zone': ClassificationRequest(
          file: fileEntry('a.pdf'),
          zone: Zone.target,
        ),
      },
    );
  });

  test('ScanCheckpoint value equality', () {
    ScanCheckpoint checkpoint({
      SourceId sourceId = testSource,
      ScanId scanId = const ScanId('s'),
      ScanStage stage = ScanStage.listing,
      ScanCursor? cursor = const ScanCursor('c'),
    }) => ScanCheckpoint(
      sourceId: sourceId,
      scanId: scanId,
      stage: stage,
      cursor: cursor,
    );

    expectValueEquality(checkpoint, {
      'sourceId': checkpoint(sourceId: const SourceId('o')),
      'scanId': checkpoint(scanId: const ScanId('o')),
      'stage': checkpoint(stage: ScanStage.finalizing),
      'cursor': checkpoint(cursor: const ScanCursor('d')),
      'no cursor': checkpoint(cursor: null),
    });
  });

  group('CancelToken', () {
    test('starts active and stays cancelled after cancel', () {
      final token = CancelToken();
      expect(token.isCancelled, isFalse);
      token
        ..cancel()
        ..cancel();
      expect(token.isCancelled, isTrue);
    });

    test('whenCancelled completes on cancel, not before', () async {
      final token = CancelToken();
      var completed = false;
      unawaited(token.whenCancelled.then((_) => completed = true));
      await pumpEventQueue();
      expect(completed, isFalse);

      token.cancel();
      await pumpEventQueue();
      expect(completed, isTrue);
    });

    test('whenCancelled of a cancelled token is already complete', () async {
      final token = CancelToken()..cancel();
      await expectLater(token.whenCancelled, completes);
    });
  });
}
