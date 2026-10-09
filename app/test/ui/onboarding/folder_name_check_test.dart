import 'dart:math';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/onboarding/folder_name_check.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/folder_names.dart';

void main() {
  Map<Category, String> withPhotos(String name) => {
    ...englishNames,
    Category.photos: name,
  };

  FolderNameProblem? problemOf(String name) =>
      folderNameProblems(withPhotos(name))[Category.photos];

  test('the approved names have no problems', () {
    expect(folderNameProblems(englishNames), isEmpty);
    expect(folderNameProblems(russianNames), isEmpty);
  });

  test('each rule', () {
    const cases = {
      '': FolderNameProblem.empty,
      'Photos/2024': FolderNameProblem.forbiddenCharacter,
      r'a\b': FolderNameProblem.forbiddenCharacter,
      'a:b': FolderNameProblem.forbiddenCharacter,
      'a*': FolderNameProblem.forbiddenCharacter,
      'a?': FolderNameProblem.forbiddenCharacter,
      'a"b': FolderNameProblem.forbiddenCharacter,
      '<a>': FolderNameProblem.forbiddenCharacter,
      'a|b': FolderNameProblem.forbiddenCharacter,
      'a\tb': FolderNameProblem.forbiddenCharacter,
      'a\u0000b': FolderNameProblem.forbiddenCharacter,
      '.photos': FolderNameProblem.leadingDot,
      '.': FolderNameProblem.leadingDot,
      '..': FolderNameProblem.leadingDot,
      'documents': FolderNameProblem.duplicate,
      'Фото 2024': null,
      'My photos (old)': null,
    };
    for (final MapEntry(key: name, value: problem) in cases.entries) {
      expect(problemOf(name), problem, reason: name);
    }
    expect(problemOf('x' * maxFolderNameLength), isNull);
    expect(
      problemOf('x' * (maxFolderNameLength + 1)),
      FolderNameProblem.tooLong,
    );
  });

  test('a duplicate is marked on the later field only', () {
    final problems = folderNameProblems({
      ...englishNames,
      Category.other: 'PHOTOS',
    });
    expect(problems, {Category.other: FolderNameProblem.duplicate});
  });

  test('names that pass here always pass the core check', () {
    final random = Random(11);
    const alphabet = 'aB.ф /\\:*?"<>|\t-_ (1)';
    var accepted = 0;
    for (var i = 0; i < 5000; i++) {
      final name = String.fromCharCodes([
        for (var j = random.nextInt(6); j >= 0; j--)
          alphabet.codeUnitAt(random.nextInt(alphabet.length)),
      ]);
      final names = withPhotos(name);
      if (folderNameProblems(names).isEmpty) {
        accepted++;
        expect(
          () => checkLayoutFolderNames(names),
          returnsNormally,
          reason: name,
        );
      }
    }
    expect(accepted, greaterThan(100));
  });

  test('names the core refuses are refused here too', () {
    for (final name in ['', '.x', 'a/b', 'a\u0000', 'Documents']) {
      expect(
        () => checkLayoutFolderNames(withPhotos(name)),
        throwsArgumentError,
        reason: name,
      );
      expect(problemOf(name), isNotNull, reason: name);
    }
  });

  test('every problem and every field has a text in both languages', () {
    for (final locale in const [Locale('en'), Locale('ru')]) {
      final l = lookupAppLocalizations(locale);
      final texts = {
        for (final problem in FolderNameProblem.values)
          folderNameProblemText(l, problem),
      };
      expect(texts, hasLength(FolderNameProblem.values.length));
      expect(texts.every((t) => t.trim().isNotEmpty), isTrue);
      final labels = {
        for (final category in Category.values)
          if (category != Category.unresolved) categoryLabel(l, category),
      };
      expect(labels, hasLength(Category.values.length - 1));
    }
  });
}
