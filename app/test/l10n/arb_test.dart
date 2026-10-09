import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The ARB files (`lib/l10n/`): every language has every message, with the
/// same placeholders as the English template.
void main() {
  Map<String, Object?> read(String language) =>
      jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
          as Map<String, Object?>;

  final template = read('en');
  Set<String> messages(Map<String, Object?> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  /// Names inside `{...}` that are placeholders (not plural cases).
  Set<String> placeholders(String message) => {
    for (final match in RegExp(r'\{(\w+)[,}]').allMatches(message))
      match.group(1)!,
  };

  test('the template describes every placeholder', () {
    for (final key in messages(template)) {
      final declared =
          ((template['@$key'] as Map<String, Object?>?)?['placeholders']
                  as Map<String, Object?>?)
              ?.keys
              .toSet() ??
          <String>{};
      expect(placeholders(template[key]! as String), declared, reason: key);
    }
  });

  for (final language in ['ru']) {
    test('$language has every message with the same placeholders', () {
      final arb = read(language);
      expect(arb['@@locale'], language);
      expect(messages(arb), messages(template));
      for (final key in messages(template)) {
        final message = arb[key]! as String;
        expect(message.trim(), isNotEmpty, reason: key);
        expect(
          placeholders(message),
          placeholders(template[key]! as String),
          reason: key,
        );
      }
    });
  }
}
