/// Dependency rules for `lib/core/`.
///
/// The core is pure Dart: it may only depend on an explicit allowlist of Dart
/// SDK libraries and pure Dart packages, and on other files inside
/// `lib/core/`. Everything else (Flutter, `dart:io`, drift, platform plugins,
/// the rest of the app) is a violation.
///
/// The rules are allowlists on purpose: adding a new dependency to the core
/// requires a deliberate edit here. Never relax these lists to make a test
/// pass; move the platform-specific code into an adapter instead.
library;

/// Name of this package as declared in `pubspec.yaml`.
const String appPackage = 'file_organizer';

/// Package-relative directory that holds the core.
const String coreDir = 'lib/core/';

/// Dart SDK libraries the core may import. All of them are platform
/// independent; `dart:io`, `dart:ui`, `dart:ffi`, `dart:html`, `dart:js*`,
/// `dart:mirrors`, `dart:isolate` and the rest are intentionally absent.
const Set<String> allowedDartLibraries = {
  'async',
  'collection',
  'convert',
  'core',
  'math',
  'typed_data',
};

/// Third-party packages the core may import. Only pure Dart packages without
/// platform code may ever be added here.
const Set<String> allowedPackages = {'collection', 'meta'};

/// A single rule violation found in a core source file.
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
List<Violation> checkCoreFile({required String path, required String source}) {
  final violations = <Violation>[];

  if (_generatedSuffixes.any(path.endsWith)) {
    violations.add(
      Violation(path, path, 'generated code is not allowed in the core'),
    );
  }

  final parsed = parseDirectives(source);

  if (parsed.unrecognized > 0) {
    violations.add(
      Violation(
        path,
        '${parsed.unrecognized} directive(s)',
        'directive-like code that the checker cannot parse; '
            'keep core directives simple',
      ),
    );
  }

  for (final directive in parsed.directives) {
    if (directive.keyword == 'part') {
      violations.add(
        Violation(
          path,
          directive.text,
          'part directives are not allowed in the core (no code generation)',
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
      final reason = _checkUri(path, uri);
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
    final main = _readLiterals(body, 0);
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
      // Keep the tokens around the comment separated.
      out.write(' ');
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

/// Optional whitespace, optional raw marker and an opening quote.
final RegExp _literal = RegExp(r'''\s*r?('{3}|"{3}|'|")''');

/// A conditional configuration up to its URI: `if (dart.library.io)`.
final RegExp _configuration = RegExp(r'\s*if\s*\([^()]*\)');

String? _checkUri(String path, String uri) {
  if (uri.contains(r'\') || uri.contains('%') || uri.contains(r'$')) {
    return 'escape sequences, percent-encoding and interpolation are not '
        'allowed in core URIs';
  }

  if (uri.startsWith('dart:')) {
    final library = uri.substring('dart:'.length);
    return allowedDartLibraries.contains(library)
        ? null
        : '$uri is not an allowed Dart SDK library for the core';
  }

  if (uri.startsWith('package:')) {
    final segments = uri.substring('package:'.length).split('/');
    if (segments.any((s) => s.isEmpty || s == '.' || s == '..')) {
      return 'package URIs in the core must not contain empty, "." or ".." '
          'segments';
    }
    final package = segments.first;
    if (package == appPackage) {
      return segments.length > 2 && segments[1] == 'core'
          ? null
          : 'the core must not depend on the rest of the app';
    }
    return allowedPackages.contains(package)
        ? null
        : 'package:$package is not an allowed pure Dart package for the core';
  }

  if (uri.contains(':')) {
    return 'only dart:, package: and relative URIs are allowed in the core';
  }

  final resolved = Uri.parse(path).resolve(uri).path;
  return resolved.startsWith(coreDir)
      ? null
      : 'relative URI leaves lib/core/ (resolves to $resolved)';
}
