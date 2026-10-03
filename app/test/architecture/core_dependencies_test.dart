// Reads the real source tree on purpose: this test checks the code, not the
// behavior of the core, so it is allowed to use dart:io.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_rules.dart';

const _file = 'lib/core/scan/scanner.dart';

List<Violation> _check(String source, {String path = _file}) =>
    checkCoreFile(path: path, source: source);

void main() {
  group('lib/core', () {
    test('exists', () {
      expect(
        Directory('lib/core').existsSync(),
        isTrue,
        reason: 'run the tests from the app/ directory',
      );
    });

    test(
      'depends only on the Dart SDK allowlist, pure packages and itself',
      () {
        final files = Directory('lib/core')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        final violations = [
          for (final file in files)
            ...checkCoreFile(
              path: file.path.replaceAll(r'\', '/'),
              source: file.readAsStringSync(),
            ),
        ];

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );
  });

  group('checker rejects', () {
    const forbidden = <String, String>{
      'dart:io': "import 'dart:io';",
      'dart:ui': "import 'dart:ui';",
      'dart:ffi': "import 'dart:ffi';",
      'dart:html': "import 'dart:html';",
      'dart:isolate': "import 'dart:isolate';",
      'dart:mirrors': "import 'dart:mirrors';",
      'flutter': "import 'package:flutter/material.dart';",
      'flutter_test': "import 'package:flutter_test/flutter_test.dart';",
      'drift': "import 'package:drift/drift.dart';",
      'platform plugin': "import 'package:path_provider/path_provider.dart';",
      'app data layer': "import 'package:file_organizer/data/db.dart';",
      'app ui layer': "import 'package:file_organizer/ui/app.dart';",
      'app main': "import 'package:file_organizer/main.dart';",
      'package dot-dot escape':
          "import 'package:file_organizer/core/../data/db.dart';",
      'relative escape': "import '../../data/db.dart';",
      'relative escape to lib': "import '../../main.dart';",
      'file uri': "import 'file:///etc/passwd.dart';",
      'export': "export 'dart:io';",
      'double quotes': 'import "dart:io";',
      'raw string': "import r'dart:io';",
      'triple quotes': "import '''dart:io''';",
      'adjacent strings': "import 'dart:' 'io';",
      'escape sequence': r"import 'dart:\x69o';",
      'show combinator': "import 'dart:io' show File;",
      'prefix': "import 'dart:io' as io;",
      'deferred': "import 'package:drift/drift.dart' deferred as drift;",
      'multi-line': "import\n  'dart:io'\n  show File;",
      'no space before uri': "import'dart:io';",
      'conditional import':
          "import 'stub.dart' if (dart.library.io) 'dart:io';",
      'second conditional uri':
          "import 'stub.dart'\n"
          "    if (dart.library.html) 'web.dart'\n"
          "    if (dart.library.io) 'package:flutter/io.dart';",
      'after library directive': "library core;\nimport 'dart:io';",
      'after annotation': "@Deprecated('x') import 'dart:io';",
      'after nested annotation': "@A(B(1)) import 'dart:io';",
      'directive the parser cannot read (safety net)':
          "@A(B(C(1))) import 'dart:io';",
      'absolute path': "import '/lib/core/model.dart';",
      'after script tag': "#!/usr/bin/env dart\nimport 'dart:io';",
      'after other imports':
          "import 'dart:async';\nimport 'dart:math';\nimport 'dart:io';",
      'after a comment': "// header\n/* block */ import 'dart:io';",
      'part': "part 'scanner.g.dart';",
      'part of uri': "part of 'scan.dart';",
      'part of name': 'part of scan;',
    };

    for (final MapEntry(key: name, value: source) in forbidden.entries) {
      test(name, () {
        expect(_check(source), isNotEmpty, reason: source);
      });
    }

    test('generated file in core', () {
      expect(_check('', path: 'lib/core/model/file_entry.g.dart'), isNotEmpty);
    });

    test('every forbidden URI in a file, not only the first', () {
      final violations = _check(
        "import 'dart:io';\n"
        "import 'dart:async';\n"
        "import 'package:flutter/widgets.dart';\n",
      );
      expect(violations.map((v) => v.subject), [
        'dart:io',
        'package:flutter/widgets.dart',
      ]);
    });
  });

  group('checker accepts', () {
    const allowed = <String, String>{
      'empty file': '',
      'allowed sdk libraries':
          "import 'dart:async';\nimport 'dart:collection';\n"
          "import 'dart:convert';\nimport 'dart:core';\n"
          "import 'dart:math';\nimport 'dart:typed_data';",
      'core package import':
          "import 'package:file_organizer/core/model/file_entry.dart';",
      'allowed pure packages':
          "import 'package:meta/meta.dart';\n"
          "import 'package:collection/collection.dart';",
      'relative import inside core': "import '../model/file_entry.dart';",
      'sibling import': "import 'scan_progress.dart';",
      'export inside core': "export 'scan_progress.dart';",
      'library directive': 'library;',
      'line comment': "// import 'dart:io';",
      'block comment': "/* import 'dart:io'; */",
      'nested block comment': "/* outer /* import 'dart:io'; */ still */",
      'doc comment': "/// Unlike `import 'dart:io';` this is pure.",
      'keyword inside a string':
          "const reason = 'skipped; import \"dart:io\" is not used';",
      'part inside a string': "const reason = 'part of a duplicate group';",
      'directive inside a multi-line string':
          "const sample = '''\nimport 'dart:io';\n''';",
      'comment marker inside a string':
          "import 'dart:async';\nconst url = 'http://example.com'; "
          "// import 'dart:io';",
      'identifier containing a keyword': 'final reimport = 1;',
    };

    for (final MapEntry(key: name, value: source) in allowed.entries) {
      test(name, () {
        final violations = _check(source);
        expect(violations, isEmpty, reason: violations.join('\n'));
      });
    }
  });
}
