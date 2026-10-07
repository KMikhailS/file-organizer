import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:file_organizer/core/ports/cancel_token.dart';
import 'package:file_organizer/core/ports/file_error.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/platform/posix/errno_kind.dart';

/// Size of each end of a file covered by the partial hash.
const int partialHashChunk = 64 * 1024;

/// Computes SHA-256 hashes of files in one long-lived worker isolate, so
/// reading large files never blocks the isolate of the app.
///
/// - The full hash is `sha256:<hex>` of the whole content, read in blocks
///   of [blockSize].
/// - The partial hash is `sha256p:<hex>` of `"<size>:"`, the first 64 KB
///   and, for files larger than 64 KB, the last 64 KB (the same definition
///   as the fake file source of the tests).
/// - A [CancelToken] is checked between blocks: the main isolate forwards
///   [CancelToken.whenCancelled] to the worker, which stops before the next
///   block and answers `cancelled`.
///
/// The worker starts on the first call. [dispose] stops it; later calls fail
/// with `ioError`.
final class HashWorker {
  HashWorker({this.blockSize = 1024 * 1024}) {
    if (blockSize < 1) {
      throw ArgumentError.value(blockSize, 'blockSize', 'must be positive');
    }
  }

  /// Bytes read per block of the full hash.
  final int blockSize;

  Future<_Connection>? _connection;

  /// Counts started workers, so an old worker that exits does not reset the
  /// connection of a newer one.
  int _generation = 0;
  final Map<int, _Pending> _pending = {};
  int _nextId = 0;
  bool _disposed = false;

  /// Hashes the file at the real path [path].
  ///
  /// [onBlock] is for tests: it is called after each block the worker has
  /// read (`block` counts from 0), and the worker waits for it before the
  /// next block, so a test can cancel [cancel] at an exact block.
  Future<FileResult<String>> hash(
    String path, {
    required bool partial,
    CancelToken? cancel,
    void Function(int block)? onBlock,
  }) async {
    if (_disposed) {
      return FileFailure.of(FileErrorKind.ioError, 'hash worker disposed');
    }
    if (cancel?.isCancelled ?? false) {
      return FileFailure.of(FileErrorKind.cancelled);
    }
    final _Connection connection;
    try {
      connection = await (_connection ??= _start());
    } on _WorkerFailed catch (e) {
      _connection = null;
      return FileFailure.of(FileErrorKind.ioError, e.message);
    }
    if (_disposed) {
      return FileFailure.of(FileErrorKind.ioError, 'hash worker disposed');
    }

    final id = _nextId++;
    final pending = _Pending(cancel, onBlock);
    _pending[id] = pending;
    connection.toWorker.send(
      _HashRequest(
        id: id,
        path: path,
        partial: partial,
        blockSize: blockSize,
        stepwise: onBlock != null,
      ),
    );
    if (cancel != null) {
      unawaited(
        cancel.whenCancelled.then((_) {
          if (_pending.containsKey(id)) {
            connection.toWorker.send(_CancelRequest(id));
          }
        }),
      );
    }
    return pending.result.future;
  }

  /// Stops the worker. Calls in progress fail with `ioError`.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final connection = _connection;
    _connection = null;
    _failAll('hash worker disposed');
    if (connection != null) {
      unawaited(
        connection.then(
          (c) => c.close(),
          // The worker never started: nothing to close.
          onError: (Object _) {},
        ),
      );
    }
  }

  Future<_Connection> _start() async {
    final generation = ++_generation;
    final fromWorker = ReceivePort('HashWorker');
    final ready = Completer<SendPort>();
    String? lastError;

    fromWorker.listen((message) {
      switch (message) {
        case final SendPort toWorker:
          ready.complete(toWorker);
        case _BlockRead(:final id, :final block):
          // Block reports come only after a request, so the worker is ready.
          unawaited(ready.future.then((port) => _onBlockRead(port, id, block)));
        case _HashDone(:final id, :final result):
          _pending.remove(id)?.result.complete(result);
        case [final Object? error, _]:
          lastError = '$error';
        case null:
          // The worker exited (shut down or crashed).
          fromWorker.close();
          final reason = 'hash worker stopped${_details(lastError)}';
          if (!ready.isCompleted) {
            ready.completeError(_WorkerFailed(reason));
          } else if (generation == _generation) {
            _connection = null;
          }
          _failAll(reason);
      }
    });

    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(
        _workerMain,
        fromWorker.sendPort,
        onExit: fromWorker.sendPort,
        onError: fromWorker.sendPort,
        debugName: 'HashWorker',
      );
    } on Object catch (e) {
      fromWorker.close();
      throw _WorkerFailed('cannot start the hash worker: $e');
    }
    return _Connection(isolate, await ready.future);
  }

  /// Lets the test hook see the block, then tells the worker whether to go
  /// on. The cancel request is sent first, so the worker stops before the
  /// next block.
  void _onBlockRead(SendPort toWorker, int id, int block) {
    final pending = _pending[id];
    if (pending != null) {
      pending.onBlock?.call(block);
      if (pending.cancel?.isCancelled ?? false) {
        toWorker.send(_CancelRequest(id));
      }
    }
    // Always answer: the worker waits for it even if the call was dropped.
    toWorker.send(_Continue(id));
  }

  void _failAll(String reason) {
    final pending = [..._pending.values];
    _pending.clear();
    for (final call in pending) {
      call.result.complete(FileFailure.of(FileErrorKind.ioError, reason));
    }
  }

  static String _details(String? error) => error == null ? '' : ': $error';
}

final class _Pending {
  _Pending(this.cancel, this.onBlock);

  final CancelToken? cancel;
  final void Function(int block)? onBlock;
  final Completer<FileResult<String>> result = Completer();
}

final class _Connection {
  _Connection(this.isolate, this.toWorker);

  final Isolate isolate;
  final SendPort toWorker;

  void close() {
    toWorker.send(const _Shutdown());
    isolate.kill(priority: Isolate.immediate);
  }
}

final class _WorkerFailed implements Exception {
  const _WorkerFailed(this.message);

  final String message;
}

// ------------------------------------------------- messages between isolates

final class _HashRequest {
  const _HashRequest({
    required this.id,
    required this.path,
    required this.partial,
    required this.blockSize,
    required this.stepwise,
  });

  final int id;
  final String path;
  final bool partial;
  final int blockSize;

  /// Whether the worker reports each block and waits for [_Continue].
  final bool stepwise;
}

final class _CancelRequest {
  const _CancelRequest(this.id);

  final int id;
}

final class _Continue {
  const _Continue(this.id);

  final int id;
}

final class _Shutdown {
  const _Shutdown();
}

final class _BlockRead {
  const _BlockRead(this.id, this.block);

  final int id;
  final int block;
}

final class _HashDone {
  const _HashDone(this.id, this.result);

  final int id;
  final FileResult<String> result;
}

// ------------------------------------------------------------ worker isolate

void _workerMain(SendPort toMain) {
  final inbox = ReceivePort('HashWorker.inbox');
  toMain.send(inbox.sendPort);
  final active = <int>{};
  final cancelled = <int>{};
  final waiting = <int, Completer<void>>{};
  final flavor = PosixFlavor.current;

  Future<void> run(_HashRequest request) async {
    final id = request.id;
    active.add(id);
    Future<void> afterBlock(int block) async {
      if (request.stepwise) {
        final next = Completer<void>();
        waiting[id] = next;
        toMain.send(_BlockRead(id, block));
        await next.future;
      }
    }

    final result = await _hashFile(
      request,
      flavor,
      isCancelled: () => cancelled.contains(id),
      afterBlock: afterBlock,
    );
    active.remove(id);
    cancelled.remove(id);
    toMain.send(_HashDone(id, result));
  }

  inbox.listen((message) {
    switch (message) {
      case final _HashRequest request:
        unawaited(run(request));
      case _CancelRequest(:final id):
        if (active.contains(id)) {
          cancelled.add(id);
        }
      case _Continue(:final id):
        waiting.remove(id)?.complete();
      case _Shutdown():
        inbox.close();
    }
  });
}

/// Reads the file of [request] block by block, checking [isCancelled]
/// before each block and calling [afterBlock] after it.
Future<FileResult<String>> _hashFile(
  _HashRequest request,
  PosixFlavor flavor, {
  required bool Function() isCancelled,
  required Future<void> Function(int block) afterBlock,
}) async {
  const cancelled = FileFailure<String>(FileError(FileErrorKind.cancelled));
  RandomAccessFile? file;
  try {
    file = await File(request.path).open();
    final length = await file.length();
    final digest = _DigestSink();
    final input = sha256.startChunkedConversion(digest);
    if (request.partial) {
      // The head, then the tail if the file is larger than one chunk.
      input.add(utf8.encode('$length:'));
      final ends = [
        0,
        if (length > partialHashChunk) length - partialHashChunk,
      ];
      for (final (block, offset) in ends.indexed) {
        if (isCancelled()) {
          return cancelled;
        }
        await file.setPosition(offset);
        input.add(await file.read(min(length, partialHashChunk)));
        await afterBlock(block);
      }
    } else {
      for (var block = 0; ; block++) {
        if (isCancelled()) {
          return cancelled;
        }
        final bytes = await file.read(request.blockSize);
        if (bytes.isEmpty) {
          break;
        }
        input.add(bytes);
        await afterBlock(block);
      }
    }
    input.close();
    final prefix = request.partial ? 'sha256p' : 'sha256';
    return FileSuccess('$prefix:${digest.value}');
  } on FileSystemException catch (e) {
    final errno = e.osError?.errorCode;
    return FileFailure.of(
      errno == null ? FileErrorKind.ioError : fileErrorKindOf(errno, flavor),
      e.message,
    );
  } on Object catch (e) {
    // Any other failure must reach the caller as a result, not kill the
    // worker with the other calls in it.
    return FileFailure.of(FileErrorKind.ioError, '$e');
  } finally {
    await file?.close();
  }
}

/// Receives the single [Digest] of a chunked conversion.
final class _DigestSink implements Sink<Digest> {
  Digest? _digest;

  String get value => _digest.toString();

  @override
  void add(Digest data) => _digest = data;

  @override
  void close() {}
}
