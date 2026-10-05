// Reads the real source tree on purpose: this test checks the code, not the
// behavior of the app, so it is allowed to use dart:io.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_rules.dart';

List<Violation> _check(String path, String source) =>
    checkLibFile(path: path, source: source);

void main() {
  test('every file in lib/ belongs to a layer and respects its rules', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    final violations = [
      for (final file in files)
        ...checkLibFile(
          path: file.path.replaceAll(r'\', '/'),
          source: file.readAsStringSync(),
        ),
    ];

    expect(files, isNotEmpty, reason: 'run the tests from the app/ directory');
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('layer roots do not overlap', () {
    for (final layer in layers) {
      final owners = layers.where((other) => other.owns(layer.root));
      expect(owners, [layer], reason: layer.root);
    }
  });

  // Each case: file path, then source.
  group('checker rejects', () {
    const forbidden = <String, (String, String)>{
      'file outside every layer': ('lib/ai/client.dart', ''),
      'file next to main': ('lib/app.dart', ''),
      // data
      'data -> platform': (
        'lib/data/db/app_database.dart',
        "import 'package:file_organizer/platform/clock.dart';",
      ),
      'data -> state': (
        'lib/data/db/app_database.dart',
        "import 'package:file_organizer/state/providers.dart';",
      ),
      'data -> flutter': (
        'lib/data/db/app_database.dart',
        "import 'package:flutter/foundation.dart';",
      ),
      'data -> dart:io': ('lib/data/db/app_database.dart', "import 'dart:io';"),
      'data relative escape to platform': (
        'lib/data/db/app_database.dart',
        "import '../../platform/clock.dart';",
      ),
      'data part outside data': (
        'lib/data/db/app_database.dart',
        "part '../../core/model/x.g.dart';",
      ),
      'data part of a package uri': (
        'lib/data/db/app_database.g.dart',
        "part of 'package:file_organizer/data/db/app_database.dart';",
      ),
      'data part of name': ('lib/data/db/app_database.g.dart', 'part of db;'),
      // platform
      'platform -> data': (
        'lib/platform/posix/posix_file_source.dart',
        "import 'package:file_organizer/data/db/app_database.dart';",
      ),
      'platform -> state': (
        'lib/platform/posix/posix_file_source.dart',
        "import 'package:file_organizer/state/providers.dart';",
      ),
      'platform -> ui': (
        'lib/platform/posix/posix_file_source.dart',
        "import 'package:file_organizer/ui/app.dart';",
      ),
      'platform -> flutter widgets': (
        'lib/platform/android/storage_api.g.dart',
        "import 'package:flutter/widgets.dart';",
      ),
      'platform -> flutter material': (
        'lib/platform/android/storage_api.g.dart',
        "import 'package:flutter/material.dart';",
      ),
      'platform -> drift': (
        'lib/platform/services/database_file.dart',
        "import 'package:drift/drift.dart';",
      ),
      'platform -> dart:ui': (
        'lib/platform/posix/posix_file_source.dart',
        "import 'dart:ui';",
      ),
      'platform -> dart:mirrors': (
        'lib/platform/posix/posix_file_source.dart',
        "import 'dart:mirrors';",
      ),
      // state
      'state -> ui': (
        'lib/state/workflow_provider.dart',
        "import 'package:file_organizer/ui/app.dart';",
      ),
      'state -> dart:io': (
        'lib/state/workflow_provider.dart',
        "import 'dart:io';",
      ),
      'state -> flutter material': (
        'lib/state/workflow_provider.dart',
        "import 'package:flutter/material.dart';",
      ),
      'state -> drift': (
        'lib/state/workflow_provider.dart',
        "import 'package:drift/drift.dart';",
      ),
      'state generated code': ('lib/state/providers.g.dart', ''),
      // ui
      'ui -> data': (
        'lib/ui/home/home_screen.dart',
        "import 'package:file_organizer/data/db/app_database.dart';",
      ),
      'ui -> platform': (
        'lib/ui/home/home_screen.dart',
        "import 'package:file_organizer/platform/clock.dart';",
      ),
      'ui -> core outside model': (
        'lib/ui/home/home_screen.dart',
        "import 'package:file_organizer/core/workflow/cleanup_workflow.dart';",
      ),
      'ui -> core ports': (
        'lib/ui/home/home_screen.dart',
        "import 'package:file_organizer/core/ports/file_source.dart';",
      ),
      'ui relative escape to platform': (
        'lib/ui/home/home_screen.dart',
        "import '../../platform/clock.dart';",
      ),
      'ui -> core model via dot-dot': (
        'lib/ui/home/home_screen.dart',
        "import 'package:file_organizer/core/model/../ports/file_source.dart';",
      ),
      'ui -> dart:io': ('lib/ui/home/home_screen.dart', "import 'dart:io';"),
      'ui -> dart:ffi': ('lib/ui/home/home_screen.dart', "import 'dart:ffi';"),
      'ui -> drift': (
        'lib/ui/home/home_screen.dart',
        "import 'package:drift/drift.dart';",
      ),
      'ui -> path_provider': (
        'lib/ui/home/home_screen.dart',
        "import 'package:path_provider/path_provider.dart';",
      ),
      'ui -> main': (
        'lib/ui/home/home_screen.dart',
        "import 'package:file_organizer/main.dart';",
      ),
      'ui conditional import of platform': (
        'lib/ui/home/home_screen.dart',
        "import 'stub.dart'\n"
            "    if (dart.library.io) 'package:file_organizer/platform/x.dart';",
      ),
      'ui part': ('lib/ui/home/home_screen.dart', "part 'home_screen.g.dart';"),
      // l10n
      'l10n -> state': (
        'lib/l10n/app_localizations.dart',
        "import 'package:file_organizer/state/providers.dart';",
      ),
      'l10n -> core': (
        'lib/l10n/app_localizations.dart',
        "import 'package:file_organizer/core/model/session.dart';",
      ),
      // main
      'main -> data': (
        'lib/main.dart',
        "import 'package:file_organizer/data/db/app_database.dart';",
      ),
      'main -> platform': (
        'lib/main.dart',
        "import 'package:file_organizer/platform/clock.dart';",
      ),
      'main -> core': (
        'lib/main.dart',
        "import 'package:file_organizer/core/workflow/cleanup_workflow.dart';",
      ),
      // core still goes through the same checker
      'core -> data': (
        'lib/core/scan/scanner.dart',
        "import 'package:file_organizer/data/db/app_database.dart';",
      ),
      'core -> dart:io': ('lib/core/scan/scanner.dart', "import 'dart:io';"),
    };

    for (final MapEntry(key: name, value: (path, source))
        in forbidden.entries) {
      test(name, () {
        expect(_check(path, source), isNotEmpty, reason: '$path\n$source');
      });
    }
  });

  group('checker accepts', () {
    const allowed = <String, (String, String)>{
      'data -> core and drift': (
        'lib/data/repositories/drift_session_repository.dart',
        "import 'package:drift/drift.dart';\n"
            "import 'package:file_organizer/core/ports/session_repository.dart';\n"
            "import 'package:file_organizer/data/db/app_database.dart';",
      ),
      'data part and generated file': (
        'lib/data/db/app_database.dart',
        "part 'app_database.g.dart';",
      ),
      'data part of': (
        'lib/data/db/app_database.g.dart',
        "part of 'app_database.dart';",
      ),
      'platform -> io, ffi, isolate, ffi and crypto packages': (
        'lib/platform/posix/posix_file_source.dart',
        "import 'dart:ffi';\nimport 'dart:io';\nimport 'dart:isolate';\n"
            "import 'package:crypto/crypto.dart';\n"
            "import 'package:ffi/ffi.dart';\n"
            "import 'package:file_organizer/core/ports/file_source.dart';",
      ),
      'platform pigeon runtime': (
        'lib/platform/android/storage_api.g.dart',
        "import 'package:flutter/foundation.dart' "
            'show ReadBuffer, WriteBuffer;\n'
            "import 'package:flutter/services.dart';",
      ),
      'platform -> generated pigeon code': (
        'lib/platform/android/android_storage.dart',
        "import 'package:file_organizer/platform/android/storage_api.g.dart';",
      ),
      'state -> core, data, platform and riverpod': (
        'lib/state/workflow_provider.dart',
        "import 'package:file_organizer/core/workflow/cleanup_workflow.dart';\n"
            "import 'package:file_organizer/data/db/app_database.dart';\n"
            "import 'package:file_organizer/platform/clock.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      ),
      'ui -> core model, state, l10n and flutter': (
        'lib/ui/home/home_screen.dart',
        "import 'package:file_organizer/core/model/session.dart';\n"
            "import 'package:file_organizer/l10n/app_localizations.dart';\n"
            "import 'package:file_organizer/state/workflow_provider.dart';\n"
            "import 'package:flutter/material.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
            "import 'package:intl/intl.dart';",
      ),
      'ui relative import inside ui': (
        'lib/ui/home/home_screen.dart',
        "import '../widgets/big_button.dart';",
      ),
      'l10n generated localizations': (
        'lib/l10n/app_localizations.dart',
        "import 'dart:async';\n"
            "import 'package:flutter/foundation.dart';\n"
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:flutter_localizations/flutter_localizations.dart';\n"
            "import 'package:intl/intl.dart' as intl;\n"
            "import 'app_localizations_en.dart';",
      ),
      'main -> ui, state, flutter and riverpod': (
        'lib/main.dart',
        "import 'package:file_organizer/state/providers.dart';\n"
            "import 'package:file_organizer/ui/app.dart';\n"
            "import 'package:flutter/material.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      ),
    };

    for (final MapEntry(key: name, value: (path, source)) in allowed.entries) {
      test(name, () {
        final violations = _check(path, source);
        expect(violations, isEmpty, reason: violations.join('\n'));
      });
    }
  });
}
