import 'dart:convert';

import 'package:file_organizer/core/model/classification_reason.dart';
import 'package:file_organizer/core/model/file_error_kind.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation_problem.dart';
import 'package:file_organizer/core/model/operation_reason.dart';

// Reasons and problems are stored as JSON objects in TEXT columns:
// `{"code": "<code>", ...parameters}`. The codes below are a storage format:
// adding one is free, renaming one is a schema change. Text that is not a
// known code (free text from schema version 1, or a code of a newer app
// version) is read back as `LegacyReason` / `LegacyProblem` with the raw
// text, never as an error.

/// [OperationReason] as stored JSON.
String encodeOperationReason(OperationReason reason) =>
    jsonEncode(switch (reason) {
      Classified(:final reason) => {
        'code': 'classified',
        'reason': _classificationJson(reason),
      },
      DuplicateOf(:final keeper) => {
        'code': 'duplicateOf',
        'keeper': keeper.value,
      },
      FolderFor(:final folder) => {'code': 'folderFor', 'folder': folder.value},
      LegacyReason(:final text) => {'code': 'legacy', 'text': text},
    });

/// Reads what [encodeOperationReason] wrote.
OperationReason decodeOperationReason(String stored) {
  final json = _object(stored);
  final decoded = json == null ? null : _operationReason(json);
  return decoded ?? LegacyReason(stored);
}

/// [OperationProblem] as stored JSON.
String encodeOperationProblem(OperationProblem problem) =>
    jsonEncode(switch (problem) {
      FileSystemError(:final kind, :final path, :final detail) => {
        'code': 'fileSystem',
        'kind': kind.name,
        'path': ?path?.value,
        'detail': ?detail,
      },
      FileGone() => {'code': 'fileGone'},
      NotAFile() => {'code': 'notAFile'},
      FileChanged() => {'code': 'fileChanged'},
      NotADuplicate() => {'code': 'notADuplicate'},
      KeeperChanged(:final keeper) => {
        'code': 'keeperChanged',
        'keeper': keeper.value,
      },
      DependsOnMissingFolder(:final folder) => {
        'code': 'dependsOnMissingFolder',
        'folder': folder.value,
      },
      FolderExists() => {'code': 'folderExists'},
      FolderNotEmpty() => {'code': 'folderNotEmpty'},
      NotWhereCleanupPutIt() => {'code': 'notWhereCleanupPutIt'},
      QuarantinePurged() => {'code': 'quarantinePurged'},
      CannotRestore() => {'code': 'cannotRestore'},
      FolderReplacedByFile(:final folder) => {
        'code': 'folderReplacedByFile',
        'folder': folder.value,
      },
      NoFreeName(:final original) => {
        'code': 'noFreeName',
        'original': original.value,
      },
      InterruptedOperation() => {'code': 'interrupted'},
      NeedsAttention(:final cause, :final errorKind) => {
        'code': 'needsAttention',
        'cause': cause.name,
        'kind': ?errorKind?.name,
      },
      LegacyProblem(:final text) => {'code': 'legacy', 'text': text},
    });

/// Reads what [encodeOperationProblem] wrote.
OperationProblem decodeOperationProblem(String stored) {
  final json = _object(stored);
  final decoded = json == null ? null : _operationProblem(json);
  return decoded ?? LegacyProblem(stored);
}

Map<String, Object?> _classificationJson(ClassificationReason reason) =>
    switch (reason) {
      ByUserRule(:final ruleId) => {'code': 'byUserRule', 'ruleId': ruleId},
      ByExtension(:final extension) => {
        'code': 'byExtension',
        'extension': extension,
      },
      ScreenshotName() => {'code': 'screenshotName'},
      ScreenshotFolder() => {'code': 'screenshotFolder'},
      AiSuggestion() => {'code': 'aiSuggestion'},
      UnknownExtension(:final extension) => {
        'code': 'unknownExtension',
        'extension': extension,
      },
      NoExtension() => {'code': 'noExtension'},
      ScreenshotNameNotImage(:final extension) => {
        'code': 'screenshotNameNotImage',
        'extension': extension,
      },
      MimeMismatch(:final mimeType, :final extension) => {
        'code': 'mimeMismatch',
        'mimeType': mimeType,
        'extension': extension,
      },
    };

OperationReason? _operationReason(Map<String, Object?> json) => switch (json) {
  {'code': 'classified', 'reason': final Map<String, Object?> reason} =>
    switch (_classificationReason(reason)) {
      final ClassificationReason r => Classified(r),
      null => null,
    },
  {'code': 'duplicateOf', 'keeper': final String keeper} => DuplicateOf(
    LogicalPath(keeper),
  ),
  {'code': 'folderFor', 'folder': final String folder} => FolderFor(
    LogicalPath(folder),
  ),
  {'code': 'legacy', 'text': final String text} => LegacyReason(text),
  _ => null,
};

ClassificationReason? _classificationReason(Map<String, Object?> json) =>
    switch (json) {
      {'code': 'byUserRule', 'ruleId': final String id} => ByUserRule(id),
      {'code': 'byExtension', 'extension': final String e} => ByExtension(e),
      {'code': 'screenshotName'} => const ScreenshotName(),
      {'code': 'screenshotFolder'} => const ScreenshotFolder(),
      {'code': 'aiSuggestion'} => const AiSuggestion(),
      {'code': 'unknownExtension', 'extension': final String e} =>
        UnknownExtension(e),
      {'code': 'noExtension'} => const NoExtension(),
      {'code': 'screenshotNameNotImage', 'extension': final String e} =>
        ScreenshotNameNotImage(e),
      {
        'code': 'mimeMismatch',
        'mimeType': final String mime,
        'extension': final String e,
      } =>
        MimeMismatch(mimeType: mime, extension: e),
      _ => null,
    };

OperationProblem? _operationProblem(Map<String, Object?> json) =>
    switch (json) {
      {'code': 'fileSystem', 'kind': final String kind} => switch (_kind(
        kind,
      )) {
        final FileErrorKind k => FileSystemError(
          k,
          path: switch (json['path']) {
            final String p => LogicalPath(p),
            _ => null,
          },
          detail: switch (json['detail']) {
            final String d => d,
            _ => null,
          },
        ),
        null => null,
      },
      {'code': 'fileGone'} => const FileGone(),
      {'code': 'notAFile'} => const NotAFile(),
      {'code': 'fileChanged'} => const FileChanged(),
      {'code': 'notADuplicate'} => const NotADuplicate(),
      {'code': 'keeperChanged', 'keeper': final String keeper} => KeeperChanged(
        LogicalPath(keeper),
      ),
      {'code': 'dependsOnMissingFolder', 'folder': final String folder} =>
        DependsOnMissingFolder(LogicalPath(folder)),
      {'code': 'folderExists'} => const FolderExists(),
      {'code': 'folderNotEmpty'} => const FolderNotEmpty(),
      {'code': 'notWhereCleanupPutIt'} => const NotWhereCleanupPutIt(),
      {'code': 'quarantinePurged'} => const QuarantinePurged(),
      {'code': 'cannotRestore'} => const CannotRestore(),
      {'code': 'folderReplacedByFile', 'folder': final String folder} =>
        FolderReplacedByFile(LogicalPath(folder)),
      {'code': 'noFreeName', 'original': final String original} => NoFreeName(
        LogicalPath(original),
      ),
      {'code': 'interrupted'} => const InterruptedOperation(),
      {'code': 'needsAttention', 'cause': final String cause} =>
        switch (AttentionCause.values.asNameMap()[cause]) {
          final AttentionCause c => switch (json['kind']) {
            null => NeedsAttention(c),
            final String kind when _kind(kind) != null => NeedsAttention(
              c,
              errorKind: _kind(kind),
            ),
            _ => null,
          },
          null => null,
        },
      {'code': 'legacy', 'text': final String text} => LegacyProblem(text),
      _ => null,
    };

FileErrorKind? _kind(String name) => FileErrorKind.values.asNameMap()[name];

/// [stored] as a JSON object, or `null` if it is not one.
Map<String, Object?>? _object(String stored) {
  try {
    return switch (jsonDecode(stored)) {
      final Map<String, Object?> map => map,
      _ => null,
    };
  } on FormatException {
    return null;
  }
}
