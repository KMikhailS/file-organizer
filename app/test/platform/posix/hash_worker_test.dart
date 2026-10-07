import 'dart:async';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/platform/posix/hash_worker.dart';
import 'package:file_organizer/platform/posix/posix_file_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/posix_sources.dart';
import '../../support/fs/temp_tree.dart';

void main() {
  late TempTree tree;
  late PosixFileSource fs;

  setUp(() async {
    tree = await TempTree.create();
    fs = await openPosix(tree.root);
  });

  LogicalPath p(String value) => LogicalPath(value);

  Future<String> ok(Future<FileResult<String>> call) async =>
      switch (await call) {
        FileSuccess(:final value) => value,
        FileFailure(:final error) => fail('expected a hash, got $error'),
      };

  List<int> pattern(int size) => List<int>.generate(size, (i) => i % 251);

  group('SHA-256 of known content', () {
    // Reference values from Python's hashlib.
    test('full hash', () async {
      tree
        ..file('empty', bytes: const [])
        ..file('abc', text: 'abc')
        ..file('200k', bytes: pattern(200 * 1024));
      expect(
        await ok(fs.fullHash(p('empty'))),
        'sha256:'
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        await ok(fs.fullHash(p('abc'))),
        'sha256:'
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        await ok(fs.fullHash(p('200k'))),
        'sha256:'
        '3a419cbb0accd5c93926e84d6b4f6106f9daa60f6ffae48ee3151b1d3809b4a7',
      );
    });

    test('partial hash: "<size>:", the first and the last 64 KB', () async {
      tree
        ..file('empty', bytes: const [])
        ..file('abc', text: 'abc')
        ..file('64k', bytes: pattern(64 * 1024))
        ..file('100k', bytes: pattern(100 * 1024))
        ..file('200k', bytes: pattern(200 * 1024));
      const expected = {
        // sha256('0:')
        'empty':
            'ba768b331fd86cec803be04e56ab2b3d4c0e98ef4ee4fcd4e72ad7cce61a1d1f',
        // sha256('3:abc')
        'abc':
            'aab5f9ae99b2e38fb462025c8f72f570c9c811705d2a4277dc855d7fa293fe97',
        // Exactly one chunk: no tail.
        '64k':
            '68cf61adb589f67ba6cebe4553761e27f24951f3b1c8d0534578d06b3c59514f',
        // Head and tail overlap.
        '100k':
            '165dd142043971ffff1e16a83bde025c55a39b7be3595dcd3227822d154e9d8a',
        '200k':
            '88b1644774a7cd7846502c42e4d01c403c2367bb9155a9a9f6678cffd3b4b723',
      };
      for (final MapEntry(key: name, value: hex) in expected.entries) {
        expect(await ok(fs.partialHash(p(name))), 'sha256p:$hex', reason: name);
      }
    });

    test('does not depend on the block size', () async {
      tree.file('200k', bytes: pattern(200 * 1024));
      final small = await openPosix(tree.root, hashBlockSize: 7);
      expect(
        await ok(small.fullHash(p('200k'))),
        await ok(fs.fullHash(p('200k'))),
      );
    });
  });

  group('cancellation', () {
    const blocks = 32;

    setUp(() => tree.file('big', bytes: List<int>.filled(blocks << 20, 7)));

    test('stops in the middle of a 32 MB file', () async {
      final token = CancelToken();
      final read = <int>[];
      fs.onHashBlock = (path, block) {
        expect(path, p('big'));
        read.add(block);
        if (block == 0) {
          token.cancel();
        }
      };
      expect(
        (await fs.fullHash(p('big'), cancel: token)).errorKind,
        FileErrorKind.cancelled,
      );
      expect(read, [0]);
    });

    test('reads every block without cancellation', () async {
      final read = <int>[];
      fs.onHashBlock = (_, block) => read.add(block);
      await ok(fs.fullHash(p('big'), cancel: CancelToken()));
      expect(read, List<int>.generate(blocks, (i) => i));
    });

    test('a cancel from outside stops a running hash', () async {
      final token = CancelToken();
      final started = Completer<void>();
      fs.onHashBlock = (_, block) {
        if (!started.isCompleted) {
          started.complete();
        }
      };
      final hashing = fs.fullHash(p('big'), cancel: token);
      await started.future;
      token.cancel();
      expect((await hashing).errorKind, FileErrorKind.cancelled);
    });

    test(
      'the worker stops on a cancel that arrives after the request',
      () async {
        // A fresh worker: the request waits for it to start, so the token is
        // cancelled after the call has passed its own check.
        final worker = HashWorker();
        addTearDown(worker.dispose);
        final token = CancelToken();
        final hashing = worker.hash(
          tree.real('big'),
          partial: false,
          cancel: token,
        );
        token.cancel();
        expect((await hashing).errorKind, FileErrorKind.cancelled);
      },
    );

    test('the partial hash stops between its two ends', () async {
      final token = CancelToken();
      final read = <int>[];
      fs.onHashBlock = (_, block) {
        read.add(block);
        token.cancel();
      };
      expect(
        (await fs.partialHash(p('big'), cancel: token)).errorKind,
        FileErrorKind.cancelled,
      );
      expect(read, [0]);
    });

    test('cancelling one call leaves the others running', () async {
      tree.file('small', text: 'abc');
      final token = CancelToken()..cancel();
      final results = await Future.wait([
        fs.fullHash(p('big'), cancel: token),
        fs.fullHash(p('small')),
      ]);
      expect(results.first.errorKind, FileErrorKind.cancelled);
      expect(results.last.isSuccess, isTrue);
    });
  });

  group('errors', () {
    test('a link, a folder and a missing file are not hashed', () async {
      tree
        ..file('a.txt')
        ..dir('dir')
        ..link('link', 'a.txt');
      expect((await fs.fullHash(p('link'))).errorKind, FileErrorKind.wrongType);
      expect(
        (await fs.partialHash(p('dir'))).errorKind,
        FileErrorKind.wrongType,
      );
      expect((await fs.fullHash(p('nope'))).errorKind, FileErrorKind.notFound);
    });

    test('an unreadable file is permissionDenied', () async {
      tree.file('secret');
      await tree.lock('secret');
      expect(
        (await fs.fullHash(p('secret'))).errorKind,
        FileErrorKind.permissionDenied,
      );
    });
  });

  group('worker', () {
    test('hashes many files at once', () async {
      for (var i = 0; i < 50; i++) {
        tree.file('f$i', text: '$i');
      }
      final hashes = await Future.wait([
        for (var i = 0; i < 50; i++) ok(fs.fullHash(p('f$i'))),
      ]);
      expect(hashes.toSet(), hasLength(50));
    });

    test('after dispose, calls fail and nothing hangs', () async {
      tree.file('a.txt');
      await ok(fs.fullHash(p('a.txt')));
      fs.dispose();
      expect((await fs.fullHash(p('a.txt'))).errorKind, FileErrorKind.ioError);
      fs.dispose();
    });

    test('dispose fails calls in progress', () async {
      tree.file('big', bytes: List<int>.filled(4 << 20, 1));
      final worker = HashWorker();
      final read = <int>[];
      final result = await worker.hash(
        tree.real('big'),
        partial: false,
        onBlock: (block) {
          read.add(block);
          worker.dispose();
        },
      );
      expect(result.errorKind, FileErrorKind.ioError);
      expect(read, [0]);
    });

    test('dispose before the first call', () async {
      HashWorker().dispose();
    });
  });
}
