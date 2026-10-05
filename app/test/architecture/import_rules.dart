/// Dependency rules for the layers of `lib/`.
///
/// Every Dart file in `lib/` belongs to exactly one [Layer]. A layer may only
/// depend on an explicit allowlist of Dart SDK libraries, packages and
/// directories of the app (see `docs/stage2_android.md`, section 11):
///
/// - `core` is pure Dart: SDK without `dart:io`, pure packages, itself;
/// - `data` adds drift; `platform` adds `dart:io`, `dart:ffi`,
///   `dart:isolate` and the Pigeon runtime; both see only `core`;
/// - `state` wires `core`, `data` and `platform` with Riverpod;
/// - `ui` sees `core/model`, `state` and `l10n`, never `data` or `platform`.
///
/// The rules are allowlists on purpose: adding a new dependency to a layer
/// requires a deliberate edit here. Never relax these lists to make a test
/// pass; move the code into the layer that is allowed to have it instead.
library;

/// Name of this package as declared in `pubspec.yaml`.
const String appPackage = 'file_organizer';

/// Package-relative directory that holds the core.
const String coreDir = 'lib/core/';

/// Dart SDK libraries that are platform independent. `dart:io`, `dart:ui`,
/// `dart:ffi`, `dart:html`, `dart:js*`, `dart:mirrors`, `dart:isolate` and
/// the rest are intentionally absent; layers add them one by one.
const Set<String> pureDartLibraries = {
  'async',
  'collection',
  'convert',
  'core',
  'math',
  'typed_data',
};

/// Pure Dart packages without platform code that every layer may use.
const Set<String> purePackages = {'collection', 'meta'};

/// Dart SDK libraries the core may import.
const Set<String> allowedDartLibraries = pureDartLibraries;

/// Third-party packages the core may import. Only pure Dart packages without
/// platform code may ever be added here.
const Set<String> allowedPackages = purePackages;

/// One layer of the app and what it may depend on.
final class Layer {
  const Layer({
    required this.name,
    required this.root,
    required this.dartLibraries,
    required this.packages,
    required this.appDirs,
    this.packageLibraries = const {},
    this.generatedCode = false,
  });

  /// Short name for messages: `core`, `data`, ...
  final String name;

  /// Package-relative directory of the layer ending with `/`, or a single
  /// file (`lib/main.dart`).
  final String root;

  /// Allowed Dart SDK libraries, without the `dart:` prefix.
  final Set<String> dartLibraries;

  /// Packages that may be imported as a whole.
  final Set<String> packages;

  /// Single libraries of otherwise forbidden packages, as
  /// `package/path.dart` (for example `flutter/services.dart`).
  final Set<String> packageLibraries;

  /// Package-relative directories (ending with `/`) or files of the app that
  /// this layer may import. Includes the layer itself.
  final List<String> appDirs;

  /// Whether generated files (`*.g.dart`) and `part` directives are allowed.
  final bool generatedCode;

  /// Whether the file at package-relative [path] belongs to this layer.
  bool owns(String path) =>
      root.endsWith('/') ? path.startsWith(root) : path == root;
}

/// The core: pure Dart domain, ports and pipeline modules.
const Layer coreLayer = Layer(
  name: 'core',
  root: coreDir,
  dartLibraries: allowedDartLibraries,
  packages: allowedPackages,
  appDirs: [coreDir],
);

/// Drift implementations of the repository ports.
const Layer dataLayer = Layer(
  name: 'data',
  root: 'lib/data/',
  dartLibraries: pureDartLibraries,
  packages: {...purePackages, 'drift'},
  appDirs: ['lib/data/', coreDir],
  // drift code generation (`part 'app_database.g.dart'`).
  generatedCode: true,
);

/// Adapters: file system (POSIX, Android), native bindings, clock, ids.
const Layer platformLayer = Layer(
  name: 'platform',
  root: 'lib/platform/',
  dartLibraries: {...pureDartLibraries, 'io', 'ffi', 'isolate'},
  packages: {...purePackages, 'ffi', 'crypto'},
  // Runtime of the Pigeon-generated channel code; widgets stay forbidden.
  packageLibraries: {'flutter/foundation.dart', 'flutter/services.dart'},
  appDirs: ['lib/platform/', coreDir],
  // Pigeon output (`*.g.dart`).
  generatedCode: true,
);

/// Riverpod providers and notifiers that wire the other layers together.
const Layer stateLayer = Layer(
  name: 'state',
  root: 'lib/state/',
  dartLibraries: pureDartLibraries,
  packages: {...purePackages, 'riverpod', 'flutter_riverpod'},
  appDirs: ['lib/state/', coreDir, 'lib/data/', 'lib/platform/'],
);

/// Screens and widgets.
const Layer uiLayer = Layer(
  name: 'ui',
  root: 'lib/ui/',
  dartLibraries: {...pureDartLibraries, 'ui'},
  // flutter_riverpod: widgets watch the providers of the state layer.
  packages: {
    ...purePackages,
    'flutter',
    'flutter_localizations',
    'flutter_riverpod',
    'intl',
  },
  appDirs: ['lib/ui/', 'lib/core/model/', 'lib/state/', 'lib/l10n/'],
);

/// ARB files and the localizations generated from them by `gen-l10n`.
const Layer l10nLayer = Layer(
  name: 'l10n',
  root: 'lib/l10n/',
  dartLibraries: {...pureDartLibraries, 'ui'},
  packages: {...purePackages, 'flutter', 'flutter_localizations', 'intl'},
  appDirs: ['lib/l10n/'],
);

/// Entry point: starts the app from the ui and state layers.
const Layer mainLayer = Layer(
  name: 'main',
  root: 'lib/main.dart',
  dartLibraries: {...pureDartLibraries, 'ui'},
  packages: {...purePackages, 'flutter', 'flutter_riverpod'},
  appDirs: ['lib/main.dart', 'lib/ui/', 'lib/state/'],
);

/// All layers. Every Dart file in `lib/` must belong to exactly one of them.
const List<Layer> layers = [
  coreLayer,
  dataLayer,
  platformLayer,
  stateLayer,
  uiLayer,
  l10nLayer,
  mainLayer,
];

/// The layer that owns package-relative [path], or `null` if none does.
Layer? layerOf(String path) {
  for (final layer in layers) {
    if (layer.owns(path)) {
      return layer;
    }
  }
  return null;
}

/// A single rule violation found in a source file.
final class Violation {
  const Violation(this.file, this.subject, this.reason);

  /// Package-relative path of the offending file.
  final String file;

  /// The offending URI or directive, or the file path for file-level rules.
  final String subject;

  /// Why this is not allowed.
  final String reason;

  @override
  String toString() => '$file: $subject — $reason';
}

/// Checks one file located in `lib/core/`.
///
/// [path] is the package-relative path with `/` separators, for example
/// `lib/core/scan/scanner.dart`. [source] is the file content.
List<Violation> checkCoreFile({required String path, required String source}) =>
    checkLayerFile(coreLayer, path: path, source: source);

/// Checks one file of `lib/`: it must belong to a layer and depend only on
/// what that layer allows.
List<Violation> checkLibFile({required String path, required String source}) {
  final layer = layerOf(path);
  if (layer == null) {
    return [
      Violation(
        path,
        path,
        'the file belongs to no layer; add the layer to '
        'test/architecture/import_rules.dart deliberately',
      ),
    ];
  }
  return checkLayerFile(layer, path: path, source: source);
}

/// Checks one file of [layer].
///
/// [path] is the package-relative path with `/` separators. [source] is the
/// file content.
List<Violation> checkLayerFile(
  Layer layer, {
  required String path,
  required String source,
}) {
  final violations = <Violation>[];
  final name = layer.name;

  if (!layer.generatedCode && _generatedSuffixes.any(path.endsWith)) {
    violations.add(
      Violation(path, path, 'generated code is not allowed in the $name'),
    );
  }

  final parsed = parseDirectives(source);

  if (parsed.unrecognized > 0) {
    violations.add(
      Violation(
        path,
        '${parsed.unrecognized} directive(s)',
        'directive-like code that the checker cannot parse; '
            'keep $name directives simple',
      ),
    );
  }

  for (final directive in parsed.directives) {
    final isPart = directive.keyword == 'part';
    if (isPart && !layer.generatedCode) {
      violations.add(
        Violation(
          path,
          directive.text,
          'part directives are not allowed in the $name (no code generation)',
        ),
      );
      continue;
    }
    if (directive.uris.isEmpty) {
      violations.add(
        Violation(path, directive.text, 'cannot read the directive URI'),
      );
    }
    for (final uri in directive.uris) {
      final reason = isPart
          ? _checkPartUri(layer, path, uri)
          : _checkUri(layer, path, uri);
      if (reason != null) {
        violations.add(Violation(path, uri, reason));
      }
    }
  }

  return violations;
}

/// An `import`, `export` or `part` directive.
final class Directive {
  const Directive(this.keyword, this.uris, this.text);

  /// `import`, `export` or `part`.
  final String keyword;

  /// The main URI followed by the URIs of conditional configurations
  /// (`if (dart.library.io) 'io_impl.dart'`).
  final List<String> uris;

  /// Source text of the directive, for error messages.
  final String text;
}

/// Finds all `import`, `export` and `part` directives in Dart [source].
///
/// Comments are ignored. Directives are recognised at statement boundaries
/// (start of file or after `;`, optionally after annotations), so words like
/// "import" inside string literals in ordinary code are not reported.
///
/// As a safety net, a second pass looks for the directive keywords followed
/// by a string literal anywhere outside comments and strings. Each such place
/// that the first pass did not recognise is counted in `unrecognized`, so the
/// checker fails loudly instead of silently skipping a directive.
({List<Directive> directives, int unrecognized}) parseDirectives(
  String source,
) {
  final code = _dropScriptTag(stripComments(source));
  final blanked = _dropScriptTag(stripComments(source, blankStrings: true));

  final directives = <Directive>[];
  final recognized = <int>{};
  for (final match in _directiveStart.allMatches(code)) {
    final keyword = match.group(1)!;
    final keywordAt = match.end - keyword.length;
    if (!blanked.startsWith(keyword, keywordAt)) {
      // The keyword is inside a string literal, not a directive.
      continue;
    }
    recognized.add(keywordAt);
    final semicolon = code.indexOf(';', match.end);
    final body = code.substring(
      match.end,
      semicolon < 0 ? code.length : semicolon,
    );
    final text = '$keyword$body'.replaceAll(RegExp(r'\s+'), ' ').trim();

    final uris = <String>[];
    // `part of 'library.dart';` names its library after `of`.
    final partOf = keyword == 'part' ? _partOf.matchAsPrefix(body) : null;
    final main = _readLiterals(body, partOf?.end ?? 0);
    if (main != null) {
      uris.add(main.value);
      var position = main.end;
      while (true) {
        final condition = _configuration.matchAsPrefix(body, position);
        if (condition == null) {
          break;
        }
        final uri = _readLiterals(body, condition.end);
        if (uri == null) {
          break;
        }
        uris.add(uri.value);
        position = uri.end;
      }
    }
    directives.add(Directive(keyword, uris, text));
  }

  final unrecognized = _looseDirective
      .allMatches(blanked)
      .where((m) => !recognized.contains(m.start))
      .length;

  return (directives: directives, unrecognized: unrecognized);
}

/// Removes `//` and (nested) `/* */` comments from Dart [source] while
/// keeping string literals intact, so that commented-out directives are
/// ignored and comment markers inside strings are not mistaken for comments.
///
/// With [blankStrings], the contents of string literals are replaced by
/// spaces (quotes are kept), which preserves every offset of the output.
String stripComments(String source, {bool blankStrings = false}) {
  final out = StringBuffer();
  final n = source.length;
  var i = 0;

  while (i < n) {
    if (source.startsWith('//', i)) {
      while (i < n && source[i] != '\n') {
        i++;
      }
    } else if (source.startsWith('/*', i)) {
      final start = i;
      var depth = 0;
      while (i < n) {
        if (source.startsWith('/*', i)) {
          depth++;
          i += 2;
        } else if (source.startsWith('*/', i)) {
          depth--;
          i += 2;
          if (depth == 0) {
            break;
          }
        } else {
          i++;
        }
      }
      // Keep the tokens around the comment separated and the line numbers
      // of the code after it.
      final lines = '\n'.allMatches(source.substring(start, i)).length;
      out.write(lines == 0 ? ' ' : '\n' * lines);
    } else if (source[i] == "'" || source[i] == '"') {
      final start = i;
      i = _skipString(source, i);
      final literal = source.substring(start, i);
      out.write(
        blankStrings
            ? '${source[start]}${' ' * (literal.length - 1)}'
            : literal,
      );
    } else {
      out.write(source[i]);
      i++;
    }
  }
  return out.toString();
}

String _dropScriptTag(String code) {
  if (!code.startsWith('#!')) {
    return code;
  }
  // Blank the line instead of removing it to keep offsets stable.
  final lineEnd = code.indexOf('\n');
  final length = lineEnd < 0 ? code.length : lineEnd;
  return ' ' * length + code.substring(length);
}

/// Returns the index right after the string literal whose opening quote is
/// at [quoteAt] in [source].
int skipStringLiteral(String source, int quoteAt) =>
    _skipString(source, quoteAt);

/// Returns the index right after the string literal whose opening quote is
/// at [quoteAt].
int _skipString(String source, int quoteAt) {
  final n = source.length;
  final raw = quoteAt > 0 && source[quoteAt - 1] == 'r';
  final quote = source[quoteAt];
  final delimiter = source.startsWith(quote * 3, quoteAt) ? quote * 3 : quote;
  var i = quoteAt + delimiter.length;
  while (i < n && !source.startsWith(delimiter, i)) {
    if (delimiter.length == 1 && source[i] == '\n') {
      // Unterminated single-line string: stop at the line end.
      return i;
    }
    i += !raw && source[i] == r'\' ? 2 : 1;
  }
  return i >= n ? n : i + delimiter.length;
}

/// Reads one string literal, or several adjacent ones (which Dart
/// concatenates), starting at [position] in [text] after optional
/// whitespace. Returns `null` if there is no literal there.
///
/// Escape sequences are not decoded: a backslash stays in the value and
/// [_checkUri] rejects it.
({String value, int end})? _readLiterals(String text, int position) {
  final value = StringBuffer();
  var end = position;
  var found = false;
  while (true) {
    final literal = _literal.matchAsPrefix(text, end);
    if (literal == null) {
      break;
    }
    found = true;
    final delimiter = literal.group(1)!;
    final close = _skipString(text, literal.end - delimiter.length);
    final contentEnd = close - delimiter.length;
    if (contentEnd > literal.end) {
      value.write(text.substring(literal.end, contentEnd));
    }
    end = close;
  }
  return found ? (value: value.toString(), end: end) : null;
}

const List<String> _generatedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.drift.dart',
  '.gr.dart',
  '.mocks.dart',
];

/// Start of a directive: at the beginning of the file or after `;`,
/// optionally preceded by metadata annotations (one level of nested
/// parentheses is supported).
final RegExp _directiveStart = RegExp(
  r'(?:^|;)\s*(?:@[\w$.]+(?:\((?:[^()]|\([^()]*\))*\))?\s*)*'
  r'(import|export|part)(?![\w$])',
);

/// A directive keyword followed by a string literal or `part of`, used on
/// code whose strings are blanked.
final RegExp _looseDirective = RegExp(
  r'''(?<![\w$.])(?:(?:import|export|part)\s*r?['"]|part\s+of(?![\w$]))''',
);

/// The `of` of a `part of` directive, right after the `part` keyword.
final RegExp _partOf = RegExp(r'\s+of(?![\w$])');

/// Optional whitespace, optional raw marker and an opening quote.
final RegExp _literal = RegExp(r'''\s*r?('{3}|"{3}|'|")''');

/// A conditional configuration up to its URI: `if (dart.library.io)`.
final RegExp _configuration = RegExp(r'\s*if\s*\([^()]*\)');

String? _checkUri(Layer layer, String path, String uri) {
  final name = layer.name;
  if (uri.contains(r'\') || uri.contains('%') || uri.contains(r'$')) {
    return 'escape sequences, percent-encoding and interpolation are not '
        'allowed in $name URIs';
  }

  if (uri.startsWith('dart:')) {
    final library = uri.substring('dart:'.length);
    return layer.dartLibraries.contains(library)
        ? null
        : '$uri is not an allowed Dart SDK library for the $name';
  }

  if (uri.startsWith('package:')) {
    final segments = uri.substring('package:'.length).split('/');
    if (segments.any((s) => s.isEmpty || s == '.' || s == '..')) {
      return 'package URIs in the $name must not contain empty, "." or ".." '
          'segments';
    }
    final package = segments.first;
    if (package == appPackage) {
      final target = 'lib/${segments.skip(1).join('/')}';
      return _allowsAppPath(layer, target)
          ? null
          : 'the $name must not depend on $target';
    }
    if (layer.packages.contains(package) ||
        layer.packageLibraries.contains(segments.join('/'))) {
      return null;
    }
    return 'package:${segments.join('/')} is not allowed for the $name';
  }

  if (uri.contains(':')) {
    return 'only dart:, package: and relative URIs are allowed in the $name';
  }

  final resolved = Uri.parse(path).resolve(uri).path;
  return _allowsAppPath(layer, resolved)
      ? null
      : 'relative URI reaches outside what the $name may import '
            '(resolves to $resolved)';
}

/// A `part` or `part of` URI must stay inside the layer's own directory.
String? _checkPartUri(Layer layer, String path, String uri) {
  if (uri.contains(':') ||
      uri.contains(r'\') ||
      uri.contains('%') ||
      uri.contains(r'$')) {
    return 'part URIs must be plain relative paths';
  }
  final resolved = Uri.parse(path).resolve(uri).path;
  return layer.owns(resolved)
      ? null
      : 'part URI leaves ${layer.root} (resolves to $resolved)';
}

bool _allowsAppPath(Layer layer, String target) => layer.appDirs.any(
  (dir) => dir.endsWith('/') ? target.startsWith(dir) : target == dir,
);
