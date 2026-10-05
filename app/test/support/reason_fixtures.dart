import 'package:file_organizer/core/model/model.dart';

// One value per class and per parameter of every reason and problem code;
// shared by the model and the storage codec tests.

/// A string equal to [value] but built at run time, so that two instances
/// built with it are never canonicalized constants.
String fresh(String value) => String.fromCharCodes(value.codeUnits);

LogicalPath path(String value) => LogicalPath(fresh(value));

List<ClassificationReason> classificationReasons() => [
  ByUserRule(fresh('cad')),
  ByUserRule(fresh('books')),
  ByExtension(fresh('pdf')),
  ByExtension(fresh('jpg')),
  const ScreenshotName(),
  const ScreenshotFolder(),
  const AiSuggestion(),
  UnknownExtension(fresh('pdf')),
  const NoExtension(),
  ScreenshotNameNotImage(fresh('pdf')),
  MimeMismatch(mimeType: fresh('image/png'), extension: fresh('pdf')),
  MimeMismatch(mimeType: fresh('image/jpeg'), extension: fresh('pdf')),
  MimeMismatch(mimeType: fresh('image/png'), extension: fresh('doc')),
];

List<OperationReason> operationReasons() => [
  Classified(ByExtension(fresh('pdf'))),
  Classified(ByExtension(fresh('txt'))),
  const Classified(ScreenshotName()),
  DuplicateOf(path('Download/a.pdf')),
  DuplicateOf(path('Download/b.pdf')),
  FolderFor(path('Download/a.pdf')),
  FolderFor(path('Фото/2024')),
  LegacyReason(fresh('extension .pdf')),
  LegacyReason(fresh('duplicate of x')),
];

List<OperationProblem> operationProblems() => [
  const FileSystemError(FileErrorKind.locked),
  const FileSystemError(FileErrorKind.ioError),
  FileSystemError(FileErrorKind.locked, path: path('a.pdf')),
  FileSystemError(FileErrorKind.locked, detail: fresh('EBUSY')),
  const FileGone(),
  const NotAFile(),
  const FileChanged(),
  const NotADuplicate(),
  KeeperChanged(path('a.pdf')),
  KeeperChanged(path('b.pdf')),
  DependsOnMissingFolder(path('a.pdf')),
  const FolderExists(),
  const FolderNotEmpty(),
  const NotWhereCleanupPutIt(),
  const QuarantinePurged(),
  const CannotRestore(),
  FolderReplacedByFile(path('a.pdf')),
  NoFreeName(path('a.pdf')),
  const InterruptedOperation(),
  const NeedsAttention(AttentionCause.fileLost),
  const NeedsAttention(AttentionCause.cannotCheck),
  const NeedsAttention(
    AttentionCause.cannotCheck,
    errorKind: FileErrorKind.permissionDenied,
  ),
  LegacyProblem(fresh('locked')),
  LegacyProblem(fresh('file is gone')),
];
