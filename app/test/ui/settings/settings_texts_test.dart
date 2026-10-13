import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/settings/settings_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/folder_names.dart';

void main() {
  test('extensions as typed: commas or spaces, dots and case do not '
      'matter', () {
    expect(parseExtensions('TXT, .md'), {'txt', 'md'});
    expect(parseExtensions(' pdf  docx;.JPG '), {'pdf', 'docx', 'jpg'});
    expect(parseExtensions(', . ,'), isEmpty);
    expect(parseExtensions(''), isEmpty);
  });

  test('a rule in one line', () {
    final l = lookupAppLocalizations(const Locale('ru'));
    final rule = ClassificationRule(
      id: 'r',
      category: Category.unresolved,
      extensions: const {'pdf', 'docx'},
      nameContains: 'Scan',
      folder: LogicalPath('Download/Telegram'),
    );
    expect(
      ruleSummaryText(l, rule, russianNames),
      '.docx, .pdf, имя содержит «scan», в Download / Telegram → '
      'Оставлять на месте',
    );
    expect(ruleTargetText(l, Category.documents, russianNames), 'Документы');
    expect(folderLabel(l, LogicalPath.root), 'Всё хранилище');
  });
}
