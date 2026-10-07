// Builds real folder trees for the platform adapter tests. Works only inside
// a fresh temporary folder, never on user folders (CLAUDE.md, "Testing
// conventions").
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// A temporary folder that is removed after the test.
final class TempTree {
  TempTree._(this.root);

  /// Creates an empty temporary folder and removes it in the test's
  /// tear-down (after making every folder inside writable again).
  static Future<TempTree> create() async {
    final dir = await Directory.systemTemp.createTemp('fo_posix_');
    final tree = TempTree._(dir.resolveSymbolicLinksSync());
    addTearDown(tree._remove);
    return tree;
  }

  /// Absolute path of the folder.
  final String root;

  final List<String> _locked = [];

  /// The absolute path of the `/`-separated [path] inside the tree.
  String real(String path) => path.isEmpty ? root : '$root/$path';

  /// Creates a file with parent folders; [text] in UTF-8 or [bytes].
  void file(
    String path, {
    String? text,
    List<int>? bytes,
    DateTime? modifiedAt,
  }) {
    final file = File(real(path))..parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes ?? utf8.encode(text ?? path));
    if (modifiedAt != null) {
      file.setLastModifiedSync(modifiedAt);
    }
  }

  /// Creates a folder with parent folders.
  void dir(String path) => Directory(real(path)).createSync(recursive: true);

  /// Creates a symbolic link at [path] pointing to [target] (as given:
  /// relative to the link's folder or absolute).
  void link(String path, String target) {
    Directory(real(path)).parent.createSync(recursive: true);
    Link(real(path)).createSync(target);
  }

  /// Creates a FIFO (named pipe) at [path].
  Future<void> fifo(String path) async {
    final result = await Process.run('mkfifo', [real(path)]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }

  /// Creates a Unix domain socket at [path]; it is closed after the test.
  Future<void> socket(String path) async {
    final server = await RawServerSocket.bind(
      InternetAddress(real(path), type: InternetAddressType.unix),
      0,
    );
    addTearDown(server.close);
  }

  /// Creates a file in [folder] whose name is the raw bytes [name] (for
  /// names that are not valid UTF-8).
  void rawNamedFile(String folder, List<int> name) {
    dir(folder);
    final path = Uint8List.fromList([
      ...utf8.encode('${real(folder)}/'),
      ...name,
    ]);
    File.fromRawPath(path).writeAsBytesSync(const [1]);
  }

  /// Takes all permissions away from the folder [path]; they are given back
  /// before the tree is removed.
  Future<void> lock(String path) async {
    await _chmod('000', real(path));
    _locked.add(real(path));
  }

  /// Gives the permissions of the folder [path] back.
  Future<void> unlock(String path) async {
    await _chmod('755', real(path));
    _locked.remove(real(path));
  }

  /// Removes the file or folder at [path], as the user would.
  ///
  /// `recursive` also lets a `File` remove a folder.
  void remove(String path) => File(real(path)).deleteSync(recursive: true);

  Future<void> _chmod(String mode, String path) async {
    final result = await Process.run('chmod', [mode, path]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }

  Future<void> _remove() async {
    for (final path in _locked) {
      await _chmod('755', path);
    }
    await Directory(root).delete(recursive: true);
  }
}
