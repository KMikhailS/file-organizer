import 'package:file_organizer/core/model/fingerprint.dart';
import 'package:file_organizer/core/model/logical_path.dart';

/// Kind of a file operation.
///
/// Which path fields an operation uses depends on its type:
///
/// | Type         | `fromPath` | `toPath`         | `fingerprint` |
/// |--------------|------------|------------------|---------------|
/// | `mkdir`      | —          | folder to create | —             |
/// | `move`       | file       | new location     | required      |
/// | `quarantine` | file       | —                | required      |
/// | `addToAlbum` | file       | —                | required      |
enum OperationType {
  mkdir,
  move,
  quarantine,
  addToAlbum;

  /// Whether the operation acts on an existing file (and so needs its
  /// fingerprint), as opposed to creating a folder.
  bool get actsOnFile => this != mkdir;

  /// Whether the operation takes a file out of the way of the user, freeing
  /// space once the quarantine is purged.
  bool get removesFile => this == quarantine || this == addToAlbum;

  /// Throws [ArgumentError] if the fields do not match this type; see the
  /// table in the type documentation. Paths must not be the source root,
  /// and a move must change the path and must not move a path into itself.
  void checkShape({
    required LogicalPath? fromPath,
    required LogicalPath? toPath,
    required Fingerprint? fingerprint,
  }) {
    Never fail(String message) => throw ArgumentError('$name: $message');

    bool isFile(LogicalPath? path) => path != null && !path.isRoot;

    switch (this) {
      case mkdir:
        if (fromPath != null) fail('fromPath must be null');
        if (!isFile(toPath)) fail('toPath must be a folder');
        if (fingerprint != null) fail('fingerprint must be null');
      case move:
        if (!isFile(fromPath)) fail('fromPath is required');
        if (!isFile(toPath)) fail('toPath is required');
        if (fingerprint == null) fail('fingerprint is required');
        if (fromPath == toPath) fail('fromPath and toPath must differ');
        if (toPath!.isWithin(fromPath!)) fail('cannot move a path into itself');
      case quarantine:
      case addToAlbum:
        if (!isFile(fromPath)) fail('fromPath is required');
        if (toPath != null) fail('toPath must be null');
        if (fingerprint == null) fail('fingerprint is required');
    }
  }
}
