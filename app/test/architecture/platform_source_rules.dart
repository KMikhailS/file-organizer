/// Source rules for `lib/platform/` (CLAUDE.md, "Architecture rules";
/// `docs/stage2_android.md`, sections 2 and 11).
///
/// File system adapters are the first code that touches real user files, so
/// the calls that can overwrite or delete them are restricted in the source:
///
/// - `rename` / `renameSync` (they replace an existing target) and the libc
///   `rename` / `renameat` are forbidden everywhere: moves go only through the
///   no-replace mechanism of decision A.5, whose "target exists" behavior is
///   covered by the `FileSource` contract tests;
/// - deletion (`delete` / `deleteSync`, libc `unlink`, `unlinkat`, `remove`,
///   `rmdir`, `truncate`, `ftruncate`) is allowed only inside the bodies of
///   `purgeQuarantined` and `removeEmptyDir`, only as a direct call and never
///   recursive;
/// - external processes (`Process`) and raw `syscall` are forbidden: they
///   would bypass every rule above.
///
/// Like the import rules, these are deliberate allowlists: never relax them
/// to make a test pass.
library;

import 'import_rules.dart';

/// Methods whose bodies may delete: the only deletions the ports allow.
const Set<String> deletionMethods = {'purgeQuarantined', 'removeEmptyDir'};

/// libc functions that replace an existing target.
const Set<String> overwritingSymbols = {'rename', 'renameat'};

/// libc functions that delete or destroy file content.
const Set<String> deletingSymbols = {
  'unlink',
  'unlinkat',
  'remove',
  'rmdir',
  'truncate',
  'ftruncate',
};

/// libc functions that bypass the checks of this file.
const Set<String> bypassSymbols = {'syscall'};

/// Checks one Dart file located in `lib/platform/`.
///
/// [path] is the package-relative path with `/` separators. [source] is the
/// file content.
List<Violation> checkPlatformSource({
  required String path,
  required String source,
}) {
  final code = stripComments(source);
  final blanked = stripComments(source, blankStrings: true);
  final bodies = _deletionBodies(blanked);
  bool inBody(int offset) =>
      bodies.any((body) => offset >= body.start && offset < body.end);

  final violations = <Violation>[];
  void report(int offset, String subject, String reason) => violations.add(
    Violation(path, 'line ${_lineOf(code, offset)}: $subject', reason),
  );

  for (final match in _member.allMatches(blanked)) {
    final name = match.group(1)!;
    if (name.startsWith('rename')) {
      report(
        match.start,
        '.$name',
        'rename replaces an existing target; move only through the '
            'no-replace mechanism of decision A.5',
      );
      continue;
    }
    if (!inBody(match.start)) {
      report(
        match.start,
        '.$name',
        'deletion is allowed only inside ${deletionMethods.join(' / ')}',
      );
      continue;
    }
    final arguments = _callArguments(blanked, match.end);
    if (arguments == null) {
      report(match.start, '.$name', 'call delete directly, not as a tear-off');
    } else if (arguments.contains('recursive')) {
      report(match.start, '.$name', 'recursive deletion is never allowed');
    }
  }

  for (final match in _process.allMatches(blanked)) {
    report(
      match.start,
      'Process',
      'external processes could move or delete files around the adapter',
    );
  }

  for (final literal in _stringLiterals(code)) {
    final symbol = literal.value;
    if (overwritingSymbols.contains(symbol)) {
      report(
        literal.start,
        "'$symbol'",
        'libc $symbol replaces an existing target; use the no-replace '
            'mechanism of decision A.5',
      );
    } else if (bypassSymbols.contains(symbol)) {
      report(
        literal.start,
        "'$symbol'",
        'raw $symbol bypasses the source rules of lib/platform/',
      );
    } else if (deletingSymbols.contains(symbol) && !inBody(literal.start)) {
      report(
        literal.start,
        "'$symbol'",
        'libc $symbol deletes; it is allowed only inside '
            '${deletionMethods.join(' / ')}',
      );
    }
  }

  return violations;
}

/// `.rename`, `.renameSync`, `.delete`, `.deleteSync` as a member access,
/// cascade or tear-off.
final RegExp _member = RegExp(
  r'\.\s*(rename|renameSync|delete|deleteSync)(?![\w$])',
);

/// The `Process` class of `dart:io`.
final RegExp _process = RegExp(r'(?<![\w$])Process(?![\w$])');

/// Start of a declaration or a call of a deletion method. Qualified calls
/// (`source.purgeQuarantined(...)`) are excluded by the look-behind.
final RegExp _deletionName = RegExp(
  '(?<![\\w\$.])(${deletionMethods.join('|')})\\s*(?:<[^<>]*>\\s*)?\\(',
);

/// What may follow the parameter list of a function declaration.
final RegExp _bodyStart = RegExp(r'\s*(?:async\*?|sync\*)?\s*(\{|=>)');

/// Offsets of the bodies of [deletionMethods] declared in [code] (comments
/// stripped, strings blanked).
List<({int start, int end})> _deletionBodies(String code) {
  final bodies = <({int start, int end})>[];
  for (final match in _deletionName.allMatches(code)) {
    final parametersEnd = _matching(code, match.end - 1);
    if (parametersEnd == null) {
      continue;
    }
    final body = _bodyStart.matchAsPrefix(code, parametersEnd);
    if (body == null) {
      // A call such as `await purgeQuarantined(ref);`, not a declaration.
      continue;
    }
    final end = body.group(1) == '{'
        ? _matching(code, body.end - 1)
        : _expressionEnd(code, body.end);
    bodies.add((start: body.end, end: end ?? code.length));
  }
  return bodies;
}

/// Arguments of the call whose name ends at [nameEnd], or `null` if the name
/// is not followed by an argument list.
String? _callArguments(String code, int nameEnd) {
  var open = nameEnd;
  while (open < code.length && code[open].trim().isEmpty) {
    open++;
  }
  if (open >= code.length || code[open] != '(') {
    return null;
  }
  final close = _matching(code, open);
  return code.substring(open + 1, close == null ? code.length : close - 1);
}

/// Index right after the bracket that closes the one at [open], or `null` if
/// it is never closed.
int? _matching(String code, int open) {
  final opening = code[open];
  final closing = switch (opening) {
    '(' => ')',
    '{' => '}',
    _ => throw ArgumentError.value(opening, 'opening'),
  };
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    if (code[i] == opening) {
      depth++;
    } else if (code[i] == closing) {
      depth--;
      if (depth == 0) {
        return i + 1;
      }
    }
  }
  return null;
}

/// Index right after the `;` that ends an `=>` body starting at [start].
int? _expressionEnd(String code, int start) {
  var depth = 0;
  for (var i = start; i < code.length; i++) {
    switch (code[i]) {
      case '(' || '[' || '{':
        depth++;
      case ')' || ']' || '}':
        depth--;
      case ';' when depth == 0:
        return i + 1;
    }
  }
  return null;
}

/// String literals of [code] (comments stripped), with their raw content.
/// Adjacent literals (`'ren' 'ame'`), which Dart concatenates, are joined.
Iterable<({int start, String value})> _stringLiterals(String code) sync* {
  var i = 0;
  while (i < code.length) {
    final char = code[i];
    if (char != "'" && char != '"') {
      i++;
      continue;
    }
    final start = i;
    final value = StringBuffer();
    while (true) {
      final quote = code[i];
      final delimiter = code.startsWith(quote * 3, i) ? 3 : 1;
      final end = skipStringLiteral(code, i);
      if (end - delimiter > i + delimiter) {
        value.write(code.substring(i + delimiter, end - delimiter));
      }
      i = end;
      final next = _adjacentLiteral.matchAsPrefix(code, i);
      if (next == null) {
        break;
      }
      i = next.end - 1;
    }
    yield (start: start, value: value.toString());
  }
}

/// Whitespace, an optional raw marker and the opening quote of a literal
/// that follows another one.
final RegExp _adjacentLiteral = RegExp(r'''\s*r?['"]''');

int _lineOf(String code, int offset) =>
    '\n'.allMatches(code.substring(0, offset)).length + 1;
