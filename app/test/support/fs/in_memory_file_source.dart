import 'dart:convert';
import 'dart:typed_data';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

import 'capability_presets.dart';
import 'fake_hash.dart';
import 'fs_call.dart';
import 'fs_snapshot.dart';

export 'capability_presets.dart';
export 'fs_call.dart';
export 'fs_snapshot.dart';

/// A file source in memory for core tests.
///
/// - Files have real content; hashes are computed from it.
/// - Capabilities are configurable (see `capability_presets.dart`); a
///   method the source cannot do fails with `unsupported`.
/// - [caseSensitive] `false` simulates Windows and Android storage, where
///   `a.jpg` and `A.JPG` are the same file.
/// - Fault injection: [failOn], [crashOn], [lock], [denyAccess].
/// - [snapshot] captures the state for "before" and "after" comparisons;
///   [calls] logs every port call.
///
/// The setup methods ([addFile], [addDir], [writeFile], [removeExternally])
/// bypass fault injection and the call log: they stand for the user or
/// other apps changing files.
class InMemoryFileSource implements FileSource {
  InMemoryFileSource({
    this.sourceId = const SourceId('test-source'),
    this.capabilities = desktopCapabilities,
    this.caseSensitive = true,
    this.pageSize = 100,
    this.appFolders = const {},
    DateTime? defaultModifiedAt,
  }) : defaultModifiedAt = (defaultModifiedAt ?? DateTime.utc(2024)).toUtc() {
    if (pageSize < 1) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be positive');
    }
  }

  @override
  final SourceId sourceId;

  @override
  final SourceCapabilities capabilities;

  /// Folders to report as the adapter's own; the fake keeps its quarantine
  /// outside the tree, so none by default.
  @override
  final Set<LogicalPath> appFolders;

  final bool caseSensitive;

  /// Maximum number of items (files and inaccessible folders) per page.
  final int pageSize;

  /// Modification time of files added without one, and of created folders.
  final DateTime defaultModifiedAt;

  /// Every port call, in order.
  final List<FsCall> calls = [];

  final Map<String, _Node> _nodes = {};
  final Map<String, _Node> _quarantine = {};
  final Map<String, LogicalPath> _album = {};
  final Set<String> _locked = {};
  final Set<String> _denied = {};
  final List<_Rule> _rules = [];
  int _quarantineCounter = 0;

  // ---------------------------------------------------------------- setup

  /// Adds a file, creating missing parent folders. The content is [bytes],
  /// or [text] in UTF-8, or by default the path itself (so files differ
  /// unless told otherwise). Returns this source for chaining.
  ///
  /// Throws [StateError] if something already exists at [path].
  InMemoryFileSource addFile(
    String path, {
    String? text,
    List<int>? bytes,
    DateTime? modifiedAt,
    DateTime? capturedAt,
  }) {
    final logical = _nonRoot(path);
    if (_nodes.containsKey(_key(logical))) {
      throw StateError('setup: $path already exists');
    }
    _ensureDirs(logical.parent!);
    _nodes[_key(logical)] = _Node.file(
      logical,
      _content(path, text, bytes),
      (modifiedAt ?? defaultModifiedAt).toUtc(),
      capturedAt?.toUtc(),
    );
    return this;
  }

  /// Adds a folder and its missing parents. Returns this source.
  InMemoryFileSource addDir(String path) {
    _ensureDirs(_nonRoot(path));
    return this;
  }

  /// Changes the content and/or modification time of an existing file, as
  /// if the user edited it.
  void writeFile(
    String path, {
    String? text,
    List<int>? bytes,
    DateTime? modifiedAt,
  }) {
    final node = _existing(path);
    if (node.isDir) {
      throw StateError('setup: $path is a folder');
    }
    _nodes[_key(node.path)] = _Node.file(
      node.path,
      text == null && bytes == null ? node.bytes : _content(path, text, bytes),
      (modifiedAt ?? node.modifiedAt).toUtc(),
      node.capturedAt,
    );
  }

  /// Removes a file or a folder with everything inside, as if the user
  /// deleted it.
  void removeExternally(String path) {
    final node = _existing(path);
    final key = _key(node.path);
    _nodes.removeWhere((k, _) => k == key || k.startsWith('$key/'));
  }

  /// Whether a file exists at [path] (ignores fault injection).
  bool isFile(String path) => _nodes[_key(LogicalPath(path))]?.isDir == false;

  /// Whether a folder exists at [path] (ignores fault injection).
  bool isDirectory(String path) =>
      path.isEmpty || (_nodes[_key(LogicalPath(path))]?.isDir ?? false);

  /// Content of the file at [path] as UTF-8 text.
  String readText(String path) => utf8.decode(readBytes(path));

  /// Content of the file at [path].
  Uint8List readBytes(String path) {
    final node = _existing(path);
    if (node.isDir) {
      throw StateError('$path is a folder');
    }
    return Uint8List.fromList(node.bytes);
  }

  /// Quarantined files by reference value, mapped to their original path.
  Map<String, LogicalPath> get quarantined => Map.unmodifiable({
    for (final MapEntry(:key, :value) in _quarantine.entries) key: value.path,
  });

  /// Paths in the "to delete" album.
  Set<LogicalPath> get album => Set.unmodifiable(_album.values);

  /// Calls that change the file system, in order.
  List<FsCall> get mutations =>
      List.unmodifiable(calls.where((c) => c.method.isMutating));

  // -------------------------------------------------------- fault injection

  /// Makes the file at [path] locked: reading, hashing, moving and
  /// quarantining it fail with `locked`.
  void lock(String path) => _locked.add(_key(LogicalPath(path)));

  void unlock(String path) => _locked.remove(_key(LogicalPath(path)));

  /// Denies access to [path] and everything inside: calls fail with
  /// `permissionDenied`, listings report the folder as inaccessible.
  void denyAccess(String path) => _denied.add(_key(LogicalPath(path)));

  void allowAccess(String path) => _denied.remove(_key(LogicalPath(path)));

  /// Makes calls fail with [kind] without any effect.
  ///
  /// Counts the calls that match: [methods] (default: all mutating
  /// methods) and, if given, [path] (the main path or the target). The
  /// [nth] matching call and the following `times - 1` ones fail.
  void failOn(
    FileErrorKind kind, {
    Set<FsMethod>? methods,
    String? path,
    int nth = 1,
    int times = 1,
    String? message,
  }) {
    _rules.add(
      _Rule(
        methods: methods ?? FsMethod.mutating,
        path: path == null ? null : _key(LogicalPath(path)),
        nth: nth,
        times: times,
        error: FileError(kind, message ?? 'injected'),
      ),
    );
  }

  /// Makes the [nth] matching call throw [SimulatedCrash] at [point], as if
  /// the process died. Matching works as in [failOn].
  void crashOn({
    Set<FsMethod>? methods,
    String? path,
    int nth = 1,
    CrashPoint point = CrashPoint.beforeEffect,
  }) {
    _rules.add(
      _Rule(
        methods: methods ?? FsMethod.mutating,
        path: path == null ? null : _key(LogicalPath(path)),
        nth: nth,
        times: 1,
        crash: point,
      ),
    );
  }

  /// Removes all [failOn] and [crashOn] rules (locks and denials stay).
  void clearFaults() => _rules.clear();

  // ------------------------------------------------------------- snapshot

  FsSnapshot snapshot() {
    SnapshotFile file(_Node node) => SnapshotFile(
      size: node.bytes.length,
      contentHash: fakeFullHash(node.bytes),
      modifiedAt: node.modifiedAt,
      capturedAt: node.capturedAt,
    );
    return FsSnapshot(
      files: {
        for (final node in _nodes.values)
          if (!node.isDir) node.path.value: file(node),
      },
      directories: {
        for (final node in _nodes.values)
          if (node.isDir) node.path.value,
      },
      quarantined: {
        for (final MapEntry(:key, :value) in _quarantine.entries)
          key: file(value),
      },
      album: {for (final path in _album.values) path.value},
    );
  }

  // ---------------------------------------------------------------- port

  @override
  Stream<FileResult<FileListPage>> list({
    ScanCursor? after,
    bool Function(LogicalPath folder)? skipFolder,
  }) async* {
    if (_deniedAt(LogicalPath.root)) {
      yield await _call(
        const FsCall(FsMethod.list, path: LogicalPath.root),
        () => FileFailure.of(FileErrorKind.permissionDenied),
      );
      return;
    }

    final items = _listItems(skipFolder);
    var start = 0;
    if (after != null) {
      while (start < items.length &&
          items[start].path.value.compareTo(after.value) <= 0) {
        start++;
      }
    }

    for (var i = start; i < items.length; i += pageSize) {
      final end = i + pageSize < items.length ? i + pageSize : items.length;
      final slice = items.sublist(i, end);
      final result = await _call(
        FsCall(FsMethod.list, path: slice.first.path),
        () => FileSuccess(
          FileListPage(
            entries: [for (final item in slice) ?item.entry],
            inaccessible: [
              for (final item in slice)
                if (item.entry == null) item.path,
            ],
            cursor: ScanCursor(slice.last.path.value),
          ),
        ),
      );
      yield result;
      if (!result.isSuccess) {
        return;
      }
    }
  }

  @override
  Future<FileResult<FileStat>> stat(LogicalPath path) =>
      _call(FsCall(FsMethod.stat, path: path), () {
        if (_deniedAt(path)) {
          return FileFailure.of(FileErrorKind.permissionDenied);
        }
        if (path.isRoot) {
          return FileSuccess(
            FileStat(
              kind: FileKind.directory,
              size: 0,
              modifiedAt: defaultModifiedAt,
            ),
          );
        }
        final node = _nodes[_key(path)];
        if (node == null) {
          return FileFailure.of(FileErrorKind.notFound);
        }
        return FileSuccess(
          FileStat(
            kind: node.isDir ? FileKind.directory : FileKind.file,
            size: node.isDir ? 0 : node.bytes.length,
            modifiedAt: node.modifiedAt,
          ),
        );
      });

  @override
  Future<FileResult<bool>> exists(LogicalPath path) =>
      _call(FsCall(FsMethod.exists, path: path), () {
        if (_deniedAt(path)) {
          return FileFailure.of(FileErrorKind.permissionDenied);
        }
        return FileSuccess(path.isRoot || _nodes.containsKey(_key(path)));
      });

  @override
  Future<FileResult<String>> partialHash(LogicalPath path) => _call(
    FsCall(FsMethod.partialHash, path: path),
    () => _readFile(path).map((node) => fakePartialHash(node.bytes)),
  );

  @override
  Future<FileResult<String>> fullHash(LogicalPath path) => _call(
    FsCall(FsMethod.fullHash, path: path),
    () => _readFile(path).map((node) => fakeFullHash(node.bytes)),
  );

  @override
  Future<FileResult<void>> mkdir(LogicalPath path) =>
      _call(FsCall(FsMethod.mkdir, path: path), () {
        if (!capabilities.canMkdir) {
          return FileFailure.of(FileErrorKind.unsupported);
        }
        final problem = _checkTarget(path);
        if (problem != null) {
          return problem;
        }
        _nodes[_key(path)] = _Node.dir(path, defaultModifiedAt);
        return succeeded;
      });

  @override
  Future<FileResult<void>> move(LogicalPath from, LogicalPath to) =>
      _call(FsCall(FsMethod.move, path: from, to: to), () {
        if (!capabilities.canMove) {
          return FileFailure.of(FileErrorKind.unsupported);
        }
        final source = _readFile(from);
        if (source case FileFailure(:final error)) {
          return FileFailure(error);
        }
        final problem = _checkTarget(to);
        if (problem != null) {
          return problem;
        }
        final node = _nodes.remove(_key(from))!;
        _nodes[_key(to)] = node.at(to);
        return succeeded;
      });

  @override
  Future<FileResult<QuarantineRef>> quarantine(
    LogicalPath path,
    SessionId sessionId,
  ) => _call(FsCall(FsMethod.quarantine, path: path), () {
    if (!capabilities.canQuarantine) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    final source = _readFile(path);
    if (source case FileFailure(:final error)) {
      return FileFailure(error);
    }
    final ref = QuarantineRef(
      '${sessionId.value}/${++_quarantineCounter}/${path.name}',
    );
    _quarantine[ref.value] = _nodes.remove(_key(path))!;
    return FileSuccess(ref);
  });

  @override
  Future<FileResult<QuarantineRef?>> findQuarantined(
    SessionId sessionId,
    LogicalPath original,
  ) => _call(FsCall(FsMethod.findQuarantined, path: original), () {
    if (!capabilities.canQuarantine) {
      return FileFailure.of(FileErrorKind.unsupported);
    }
    final prefix = '${sessionId.value}/';
    for (final MapEntry(:key, :value) in _quarantine.entries) {
      if (key.startsWith(prefix) && _key(value.path) == _key(original)) {
        return FileSuccess(QuarantineRef(key));
      }
    }
    return const FileSuccess(null);
  });

  @override
  Future<FileResult<void>> restore(QuarantineRef ref, LogicalPath to) =>
      _call(FsCall(FsMethod.restore, ref: ref, to: to), () {
        if (!capabilities.quarantineRestorable) {
          return FileFailure.of(FileErrorKind.unsupported);
        }
        final node = _quarantine[ref.value];
        if (node == null) {
          return FileFailure.of(FileErrorKind.notFound, 'quarantine: $ref');
        }
        final problem = _checkTarget(to);
        if (problem != null) {
          return problem;
        }
        _quarantine.remove(ref.value);
        _nodes[_key(to)] = node.at(to);
        return succeeded;
      });

  @override
  Future<FileResult<void>> removeEmptyDir(LogicalPath path) =>
      _call(FsCall(FsMethod.removeEmptyDir, path: path), () {
        if (!capabilities.canMkdir || path.isRoot) {
          return FileFailure.of(FileErrorKind.unsupported);
        }
        if (_deniedAt(path)) {
          return FileFailure.of(FileErrorKind.permissionDenied);
        }
        final key = _key(path);
        final node = _nodes[key];
        if (node == null) {
          return FileFailure.of(FileErrorKind.notFound);
        }
        if (!node.isDir) {
          return FileFailure.of(FileErrorKind.wrongType);
        }
        if (_nodes.keys.any((k) => k.startsWith('$key/'))) {
          return FileFailure.of(FileErrorKind.notEmpty);
        }
        _nodes.remove(key);
        return succeeded;
      });

  @override
  Future<FileResult<void>> purgeQuarantined(QuarantineRef ref) =>
      _call(FsCall(FsMethod.purgeQuarantined, ref: ref), () {
        if (!capabilities.canQuarantine) {
          return FileFailure.of(FileErrorKind.unsupported);
        }
        if (_quarantine.remove(ref.value) == null) {
          return FileFailure.of(FileErrorKind.notFound);
        }
        return succeeded;
      });

  @override
  Future<FileResult<void>> addToAlbum(LogicalPath path) =>
      _call(FsCall(FsMethod.addToAlbum, path: path), () {
        if (!capabilities.canAddToAlbum) {
          return FileFailure.of(FileErrorKind.unsupported);
        }
        final source = _readFile(path);
        if (source case FileFailure(:final error)) {
          return FileFailure(error);
        }
        if (_album.containsKey(_key(path))) {
          return FileFailure.of(FileErrorKind.targetExists, 'already in album');
        }
        _album[_key(path)] = path;
        return succeeded;
      });

  @override
  Future<FileResult<void>> removeFromAlbum(LogicalPath path) =>
      _call(FsCall(FsMethod.removeFromAlbum, path: path), () {
        if (!capabilities.canAddToAlbum) {
          return FileFailure.of(FileErrorKind.unsupported);
        }
        if (_album.remove(_key(path)) == null) {
          return FileFailure.of(FileErrorKind.notFound, 'not in album');
        }
        return succeeded;
      });

  // ------------------------------------------------------------ internals

  Future<FileResult<T>> _call<T>(
    FsCall call,
    FileResult<T> Function() effect,
  ) async {
    calls.add(call);
    CrashPoint? crash;
    FileError? injected;
    for (final rule in _rules) {
      if (!rule.matches(call, _key)) {
        continue;
      }
      rule.seen++;
      if (!rule.fires) {
        continue;
      }
      crash ??= rule.crash;
      injected ??= rule.error;
    }

    if (crash == CrashPoint.beforeEffect) {
      throw SimulatedCrash(call, crash!);
    }
    final result = injected != null ? FileFailure<T>(injected) : effect();
    if (crash == CrashPoint.afterEffect) {
      throw SimulatedCrash(call, crash!);
    }
    return result;
  }

  /// The file at [path] if it can be read.
  FileResult<_Node> _readFile(LogicalPath path) {
    if (_deniedAt(path)) {
      return FileFailure.of(FileErrorKind.permissionDenied);
    }
    if (path.isRoot) {
      return FileFailure.of(FileErrorKind.wrongType);
    }
    final node = _nodes[_key(path)];
    if (node == null) {
      return FileFailure.of(FileErrorKind.notFound);
    }
    if (node.isDir) {
      return FileFailure.of(FileErrorKind.wrongType);
    }
    if (_locked.contains(_key(path))) {
      return FileFailure.of(FileErrorKind.locked);
    }
    return FileSuccess(node);
  }

  /// Why nothing can be created at [path], or `null` if it can.
  FileResult<void>? _checkTarget(LogicalPath path) {
    if (_deniedAt(path)) {
      return FileFailure.of(FileErrorKind.permissionDenied);
    }
    if (path.isRoot || _nodes.containsKey(_key(path))) {
      return FileFailure.of(FileErrorKind.targetExists);
    }
    final parent = path.parent!;
    if (!parent.isRoot) {
      final parentNode = _nodes[_key(parent)];
      if (parentNode == null) {
        return FileFailure.of(FileErrorKind.notFound, 'no folder $parent');
      }
      if (!parentNode.isDir) {
        return FileFailure.of(FileErrorKind.wrongType, '$parent is a file');
      }
    }
    return null;
  }

  bool _deniedAt(LogicalPath path) {
    if (_denied.isEmpty) {
      return false;
    }
    for (LogicalPath? p = path; p != null; p = p.parent) {
      if (_denied.contains(_key(p))) {
        return true;
      }
    }
    return false;
  }

  List<_ListItem> _listItems(bool Function(LogicalPath folder)? skipFolder) {
    final children = <String, List<_Node>>{};
    for (final node in _nodes.values) {
      (children[_key(node.path.parent!)] ??= []).add(node);
    }

    final items = <_ListItem>[];
    void visit(LogicalPath folder) {
      for (final node in children[_key(folder)] ?? const <_Node>[]) {
        if (node.isDir) {
          if (skipFolder?.call(node.path) ?? false) {
            continue;
          }
          if (_denied.contains(_key(node.path))) {
            items.add(_ListItem(node.path, null));
            continue;
          }
          visit(node.path);
        } else {
          items.add(
            _ListItem(
              node.path,
              FileEntry(
                sourceId: sourceId,
                path: node.path,
                size: node.bytes.length,
                modifiedAt: node.modifiedAt,
                capturedAt: capabilities.providesCapturedAt
                    ? node.capturedAt
                    : null,
              ),
            ),
          );
        }
      }
    }

    visit(LogicalPath.root);
    return items..sort((a, b) => a.path.compareTo(b.path));
  }

  String _key(LogicalPath path) =>
      caseSensitive ? path.value : path.value.toLowerCase();

  LogicalPath _nonRoot(String path) {
    final logical = LogicalPath(path);
    if (logical.isRoot) {
      throw ArgumentError.value(path, 'path', 'must not be the root');
    }
    return logical;
  }

  _Node _existing(String path) {
    final node = _nodes[_key(LogicalPath(path))];
    if (node == null) {
      throw StateError('setup: nothing at $path');
    }
    return node;
  }

  void _ensureDirs(LogicalPath folder) {
    if (folder.isRoot) {
      return;
    }
    _ensureDirs(folder.parent!);
    final existing = _nodes[_key(folder)];
    if (existing == null) {
      _nodes[_key(folder)] = _Node.dir(folder, defaultModifiedAt);
    } else if (!existing.isDir) {
      throw StateError('setup: $folder is a file');
    }
  }

  static Uint8List _content(String path, String? text, List<int>? bytes) =>
      Uint8List.fromList(bytes ?? utf8.encode(text ?? path));
}

final class _Node {
  _Node.file(this.path, this.bytes, this.modifiedAt, this.capturedAt)
    : isDir = false;

  _Node.dir(this.path, this.modifiedAt)
    : isDir = true,
      bytes = Uint8List(0),
      capturedAt = null;

  _Node._(this.path, this.isDir, this.bytes, this.modifiedAt, this.capturedAt);

  final LogicalPath path;
  final bool isDir;
  final Uint8List bytes;
  final DateTime modifiedAt;
  final DateTime? capturedAt;

  /// The same node at another path (content and dates are kept).
  _Node at(LogicalPath to) => _Node._(to, isDir, bytes, modifiedAt, capturedAt);
}

final class _ListItem {
  const _ListItem(this.path, this.entry);

  final LogicalPath path;

  /// The file, or `null` for an inaccessible folder.
  final FileEntry? entry;
}

final class _Rule {
  _Rule({
    required this.methods,
    required this.path,
    required this.nth,
    required this.times,
    this.error,
    this.crash,
  }) {
    if (nth < 1 || times < 1) {
      throw ArgumentError('nth and times must be positive');
    }
  }

  final Set<FsMethod> methods;
  final String? path;
  final int nth;
  final int times;
  final FileError? error;
  final CrashPoint? crash;

  int seen = 0;

  bool get fires => seen >= nth && seen < nth + times;

  bool matches(FsCall call, String Function(LogicalPath) key) {
    if (!methods.contains(call.method)) {
      return false;
    }
    if (path == null) {
      return true;
    }
    return (call.path != null && key(call.path!) == path) ||
        (call.to != null && key(call.to!) == path);
  }
}

extension on FileResult<_Node> {
  FileResult<T> map<T>(T Function(_Node node) f) => switch (this) {
    FileSuccess(:final value) => FileSuccess(f(value)),
    FileFailure(:final error) => FileFailure(error),
  };
}
