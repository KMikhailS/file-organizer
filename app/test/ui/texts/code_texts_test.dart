import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/texts/problem_texts.dart';
import 'package:file_organizer/ui/texts/reason_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Texts for the codes of reasons and problems (`docs/stage2_android.md`,
/// 3.1) in both languages. The switches are exhaustive, so a new code
/// without a text does not compile; these tests check what the texts say.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));
  final cyrillic = RegExp('[а-яё]', caseSensitive: false);

  final keeper = LogicalPath('DCIM/Camera/IMG_1.jpg');
  final folder = LogicalPath('Фото/2024');

  /// Every code, with the parameters its text must show.
  final reasons = <(OperationReason, List<String>)>[
    (DuplicateOf(keeper), [keeper.value]),
    (FolderFor(folder), [folder.value]),
    (MovePlaceholder(keeper), [keeper.value]),
    (const Classified(ByUserRule('rule-1')), []),
    (const Classified(ByExtension('pdf')), ['.pdf']),
    (const Classified(ScreenshotName()), []),
    (const Classified(ScreenshotFolder()), []),
    (const Classified(AiSuggestion()), []),
    (const Classified(UnknownExtension('xyz')), ['.xyz']),
    (const Classified(NoExtension()), []),
    (const Classified(ScreenshotNameNotImage('pdf')), ['.pdf']),
    (
      const Classified(MimeMismatch(mimeType: 'video/mp4', extension: 'jpg')),
      ['video/mp4', '.jpg'],
    ),
  ];

  final problems = <(OperationProblem, List<String>)>[
    (const FileSystemError(FileErrorKind.locked), []),
    (
      FileSystemError(FileErrorKind.notFound, path: folder, detail: 'ENOENT'),
      [folder.value],
    ),
    (const FileGone(), []),
    (const NotAFile(), []),
    (const FileChanged(), []),
    (const NotADuplicate(), []),
    (KeeperChanged(keeper), [keeper.value]),
    (DependsOnMissingFolder(folder), [folder.value]),
    (const FolderExists(), []),
    (const FolderNotEmpty(), []),
    (const NotWhereCleanupPutIt(), []),
    (const QuarantinePurged(), []),
    (const CannotRestore(), []),
    (FolderReplacedByFile(folder), [folder.value]),
    (NoFreeName(keeper), [keeper.value]),
    (const InterruptedOperation(), []),
    (const NeedsAttention(AttentionCause.fileLost), []),
    (const NeedsAttention(AttentionCause.cannotCheck), []),
    (const NeedsAttention(AttentionCause.cannotSearchQuarantine), []),
    (
      const NeedsAttention(
        AttentionCause.cannotCheck,
        errorKind: FileErrorKind.permissionDenied,
      ),
      [],
    ),
  ];

  void checkFamily<T>(
    String family,
    List<(T, List<String>)> samples,
    String Function(AppLocalizations l, T code) text,
  ) {
    for (final (name, l) in [('en', en), ('ru', ru)]) {
      test('$family, $name: every code has its own text with its '
          'parameters', () {
        final texts = <String>{};
        for (final (code, parameters) in samples) {
          final shown = text(l, code);
          expect(shown.trim(), isNotEmpty, reason: '$code');
          expect(texts.add(shown), isTrue, reason: '$code: "$shown" twice');
          for (final parameter in parameters) {
            expect(shown, contains(parameter), reason: '$code');
          }
          if (name == 'ru') {
            expect(shown, contains(cyrillic), reason: '$code: "$shown"');
          }
        }
      });
    }

    test('$family: the languages differ', () {
      for (final (code, _) in samples) {
        expect(text(en, code), isNot(text(ru, code)), reason: '$code');
      }
    });
  }

  checkFamily('operation reasons', reasons, operationReasonText);
  checkFamily('operation problems', problems, operationProblemText);
  checkFamily('file errors', [
    for (final kind in FileErrorKind.values) (kind, const <String>[]),
  ], fileErrorText);
  checkFamily('attention causes', [
    for (final cause in AttentionCause.values) (cause, const <String>[]),
  ], attentionCauseText);

  test('technical details of a file error are never shown', () {
    const problem = FileSystemError(
      FileErrorKind.ioError,
      detail: 'errno 5 (EIO)',
    );
    for (final l in [en, ru]) {
      expect(operationProblemText(l, problem), isNot(contains('EIO')));
      expect(
        operationProblemText(l, problem),
        fileErrorText(l, FileErrorKind.ioError),
      );
    }
  });

  test('a file error names the path it is about', () {
    final problem = FileSystemError(FileErrorKind.notFound, path: folder);
    expect(operationProblemText(en, problem), 'Not found: Фото/2024');
    expect(operationProblemText(ru, problem), 'Не найдено: Фото/2024');
  });

  test('needs attention says why, and the error behind it', () {
    expect(
      operationProblemText(
        ru,
        const NeedsAttention(
          AttentionCause.cannotCheck,
          errorKind: FileErrorKind.permissionDenied,
        ),
      ),
      'Требует внимания: файл не удалось проверить (Нет доступа)',
    );
  });

  test('texts written before the codes are shown as they are', () {
    expect(operationReasonText(ru, const LegacyReason('old text')), 'old text');
    expect(
      operationProblemText(ru, const LegacyProblem('old problem')),
      'old problem',
    );
  });

  test('the root of the source is shown as /', () {
    expect(
      operationReasonText(en, const FolderFor(LogicalPath.root)),
      'Needed for /',
    );
  });
}
