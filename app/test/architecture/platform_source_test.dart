// Reads the real source tree on purpose: this test checks the code, not the
// behavior of the adapters, so it is allowed to use dart:io.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'platform_source_rules.dart';

const _file = 'lib/platform/posix/posix_file_source.dart';

List<String> _check(String source) => [
  for (final violation in checkPlatformSource(path: _file, source: source))
    violation.toString(),
];

void main() {
  test('lib/platform never renames, deletes only where allowed', () {
    final dir = Directory('lib/platform');
    final files = dir.existsSync()
        ? dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
        : const <File>[];

    final violations = [
      for (final file in files)
        ...checkPlatformSource(
          path: file.path.replaceAll(r'\', '/'),
          source: file.readAsStringSync(),
        ),
    ];

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('checker rejects', () {
    const forbidden = <String, String>{
      'File.rename': "Future<void> move(File f) => f.rename('/b');",
      'renameSync': "void move(File f) { f.renameSync('/b'); }",
      'Directory.rename': "void move(Directory d) { d.rename('/b'); }",
      'rename as a cascade': "void move(File f) { f..rename('/b'); }",
      'rename as a null-aware call': "void move(File? f) { f?.rename('/b'); }",
      'rename as a tear-off': 'final mover = File("a").rename;',
      'rename inside purgeQuarantined':
          "void purgeQuarantined(QuarantineRef ref) { f.rename('/b'); }",
      'delete in another method':
          'Future<void> move(File f) async { await f.delete(); }',
      'deleteSync at top level': "final _ = File('a').deleteSync();",
      'delete in a method that calls purgeQuarantined':
          'void cleanUp() { purgeQuarantined(ref); f.delete(); }',
      'delete after the body of purgeQuarantined':
          'void purgeQuarantined(QuarantineRef ref) { log(); }\n'
          'void other() { f.deleteSync(); }',
      'recursive delete inside purgeQuarantined':
          'void purgeQuarantined(QuarantineRef ref) {\n'
          '  dir.deleteSync(recursive: true);\n'
          '}',
      'delete tear-off inside removeEmptyDir':
          'void removeEmptyDir(String p) { paths.forEach(dir.delete); }',
      'libc rename': "final f = lib.lookupFunction<A, B>('rename');",
      'libc renameat': 'final f = lib.lookupFunction<A, B>("renameat");',
      'libc renameat in another function':
          'int moveFile(String a, String b) {\n'
          "  final f = lib.lookupFunction<A, B>('renameat');\n"
          '}',
      'libc renameat after the placeholder function':
          'int _renameOntoOwnPlaceholder(String a, String b) { return 0; }\n'
          "final f = lib.lookupFunction<A, B>('renameat');",
      'libc renameat in a function with a longer name':
          'int _renameOntoOwnPlaceholder2(String a) {\n'
          "  lib.lookup('renameat');\n"
          '}',
      'libc rename inside the placeholder function':
          'int _renameOntoOwnPlaceholder(String a, String b) {\n'
          "  lib.lookup('rename');\n"
          '}',
      'File.rename inside the placeholder function':
          'int _renameOntoOwnPlaceholder(File a, String b) {\n'
          '  a.renameSync(b);\n'
          '}',
      'libc unlink inside the placeholder function':
          'int _renameOntoOwnPlaceholder(String a, String b) {\n'
          "  lib.lookup('unlink');\n"
          '}',
      'libc rename as adjacent strings':
          "final f = lib.lookupFunction<A, B>('ren' 'ame');",
      'libc rename as a raw string': "final f = lib.lookup(r'rename');",
      'libc unlink outside the deletion methods':
          "final f = lib.lookupFunction<A, B>('unlink');",
      'libc unlinkat outside the deletion methods':
          "final f = lib.lookupFunction<A, B>('unlinkat');",
      'libc remove outside the deletion methods':
          "final f = lib.lookupFunction<A, B>('remove');",
      'libc rmdir outside the deletion methods':
          "final f = lib.lookupFunction<A, B>('rmdir');",
      'libc truncate': "final f = lib.lookupFunction<A, B>('truncate');",
      'libc ftruncate': "final f = lib.lookupFunction<A, B>('ftruncate');",
      'libc syscall': "final f = lib.lookupFunction<A, B>('syscall');",
      'syscall inside purgeQuarantined':
          "void purgeQuarantined(QuarantineRef r) { lib.lookup('syscall'); }",
      'Process.run': "Future<void> mv() => Process.run('mv', ['a', 'b']);",
      'Process.start': "void rm() { Process.start('rm', ['a']); }",
      'Process import': "import 'dart:io' show File, Process;",
    };

    for (final MapEntry(key: name, value: source) in forbidden.entries) {
      test(name, () {
        expect(_check(source), isNotEmpty, reason: source);
      });
    }

    test('reports the line of the violation', () {
      final violations = _check(
        '/* a\n   block comment */\n'
        'void move(File f) {\n'
        '  // f.rename is mentioned only here\n'
        "  f.renameSync('/b');\n"
        '}',
      );
      expect(violations, hasLength(1));
      expect(violations.single, contains('line 5'));
    });
  });

  group('checker accepts', () {
    const allowed = <String, String>{
      'empty file': '',
      'delete inside purgeQuarantined':
          'Future<PurgeResult> purgeQuarantined(QuarantineRef ref) async {\n'
          '  await File(path).delete();\n'
          '  await descriptor.delete();\n'
          '  return const PurgeResult.ok();\n'
          '}',
      'deleteSync inside purgeQuarantined with nested blocks':
          'PurgeResult purgeQuarantined(QuarantineRef ref) {\n'
          '  if (valid(ref)) {\n'
          '    for (final f in files) { f.deleteSync(); }\n'
          '  }\n'
          '  return ok;\n'
          '}',
      'delete inside an arrow body of removeEmptyDir':
          'Future<void> removeEmptyDir(String path) => '
          'Directory(path).delete();',
      'libc rmdir inside removeEmptyDir':
          'int removeEmptyDir(String path) {\n'
          "  final rmdir = lib.lookupFunction<A, B>('rmdir');\n"
          '  return rmdir(path.toNativeUtf8());\n'
          '}',
      'libc unlink inside purgeQuarantined':
          'void purgeQuarantined(QuarantineRef ref) {\n'
          "  lib.lookupFunction<A, B>('unlink')(p);\n"
          '}',
      'generic deletion method':
          'Future<R> purgeQuarantined<R>(QuarantineRef ref) async {\n'
          '  await f.delete();\n'
          '}',
      'libc renameat inside _renameOntoOwnPlaceholder':
          'int _renameOntoOwnPlaceholder(Libc libc, String a, String b) {\n'
          "  final f = _renameat ??= lib.lookupFunction<A, B>('renameat');\n"
          '  return f(a, b);\n'
          '}',
      'renameat2 and mkdir':
          "final renameat2 = lib.lookupFunction<A, B>('renameat2');\n"
          "final mkdir = lib.lookupFunction<A, B>('mkdir');",
      'names that only contain the forbidden words':
          'void renamed() { f.deleted; f.renameat2(); x.deleteLater(); }',
      'own move method': 'Future<MoveResult> move(String a, String b) async {}',
      'forbidden words in comments':
          "// Never call File.rename or 'unlink' here.\n"
          "/* f.delete(); Process.run('rm'); */",
      'forbidden words inside longer strings':
          "const reason = 'rename would replace the target';",
      'ProcessInfo for memory usage': 'final rss = ProcessInfo.currentRss;',
      'list.remove and map.remove':
          'void f() { list.remove(1); map.remove(2); }',
    };

    for (final MapEntry(key: name, value: source) in allowed.entries) {
      test(name, () {
        final violations = _check(source);
        expect(violations, isEmpty, reason: violations.join('\n'));
      });
    }
  });
}
