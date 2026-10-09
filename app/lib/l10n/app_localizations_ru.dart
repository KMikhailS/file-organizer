// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'File Organizer';

  @override
  String get folderDocuments => 'Документы';

  @override
  String get folderPhotos => 'Фото';

  @override
  String get folderVideos => 'Видео';

  @override
  String get folderScreenshots => 'Скриншоты';

  @override
  String get folderMusic => 'Музыка';

  @override
  String get folderArchives => 'Архивы';

  @override
  String get folderInstallers => 'Установщики';

  @override
  String get folderOther => 'Другое';

  @override
  String get restoredLabel => 'восстановлено';

  @override
  String get internalStorage => 'Внутреннее хранилище';

  @override
  String get notificationChannel => 'Ход уборки';

  @override
  String get progressScanning => 'Просматриваю файлы';

  @override
  String get progressAnalyzing => 'Ищу дубли';

  @override
  String get progressExecuting => 'Навожу порядок';

  @override
  String get progressUndoing => 'Отменяю уборку';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return '$_temp0';
  }

  @override
  String stepOf(int done, int total) {
    return '$done из $total';
  }

  @override
  String reasonDuplicateOf(String keeper) {
    return 'Копия файла $keeper';
  }

  @override
  String reasonFolderFor(String folder) {
    return 'Нужна для папки $folder';
  }

  @override
  String reasonMovePlaceholder(String file) {
    return 'Пустая заготовка от прерванного перемещения $file';
  }

  @override
  String get classifiedByUserRule => 'По вашему правилу';

  @override
  String classifiedByExtension(String extension) {
    return 'По расширению .$extension';
  }

  @override
  String get classifiedScreenshotName => 'Имя похоже на скриншот';

  @override
  String get classifiedScreenshotFolder => 'Лежит в папке скриншотов';

  @override
  String get classifiedAiSuggestion => 'Предложено ИИ';

  @override
  String unresolvedUnknownExtension(String extension) {
    return 'Неизвестное расширение .$extension';
  }

  @override
  String get unresolvedNoExtension => 'Нет расширения';

  @override
  String unresolvedScreenshotNameNotImage(String extension) {
    return 'Имя как у скриншота, но это не изображение (.$extension)';
  }

  @override
  String unresolvedMimeMismatch(String mimeType, String extension) {
    return 'Содержимое ($mimeType) не совпадает с расширением .$extension';
  }

  @override
  String problemAt(String problem, String path) {
    return '$problem: $path';
  }

  @override
  String get problemFileGone => 'Файла больше нет';

  @override
  String get problemNotAFile => 'Это больше не файл';

  @override
  String get problemFileChanged => 'Файл изменился после сканирования';

  @override
  String get problemNotADuplicate => 'Это больше не дубль';

  @override
  String problemKeeperChanged(String keeper) {
    return 'Оставляемая копия $keeper изменилась или пропала';
  }

  @override
  String problemDependsOnMissingFolder(String folder) {
    return 'Не удалось создать папку $folder';
  }

  @override
  String get problemFolderExists => 'Папка уже существует';

  @override
  String get problemFolderNotEmpty => 'В папке есть файлы';

  @override
  String get problemNotWhereCleanupPutIt =>
      'Файл уже не там, куда его положила уборка';

  @override
  String get problemQuarantinePurged => 'Карантин очищен: файл не вернуть';

  @override
  String get problemCannotRestore => 'Файл не удаётся вернуть из карантина';

  @override
  String problemFolderReplacedByFile(String folder) {
    return '$folder теперь файл, а не папка';
  }

  @override
  String problemNoFreeName(String original) {
    return 'Имя $original и все имена «восстановлено» рядом с ним заняты';
  }

  @override
  String get problemInterrupted => 'Прервано до выполнения';

  @override
  String problemNeedsAttention(String cause) {
    return 'Требует внимания: $cause';
  }

  @override
  String problemNeedsAttentionBecause(String cause, String error) {
    return 'Требует внимания: $cause ($error)';
  }

  @override
  String get attentionFileLost => 'файла нет ни на старом, ни на новом месте';

  @override
  String get attentionCannotCheck => 'файл не удалось проверить';

  @override
  String get attentionCannotSearchQuarantine =>
      'не удалось просмотреть карантин';

  @override
  String get fileErrorNotFound => 'Не найдено';

  @override
  String get fileErrorTargetExists => 'Имя уже занято';

  @override
  String get fileErrorPermissionDenied => 'Нет доступа';

  @override
  String get fileErrorLocked => 'Занято другим приложением';

  @override
  String get fileErrorUnsupported => 'Хранилище этого не позволяет';

  @override
  String get fileErrorNotEmpty => 'Папка не пуста';

  @override
  String get fileErrorWrongType => 'Файл вместо папки или наоборот';

  @override
  String get fileErrorCancelled => 'Отменено';

  @override
  String get fileErrorIoError => 'Ошибка чтения или записи';

  @override
  String sizeBytes(String size) {
    return '$size Б';
  }

  @override
  String sizeKilobytes(String size) {
    return '$size КБ';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size МБ';
  }

  @override
  String sizeGigabytes(String size) {
    return '$size ГБ';
  }

  @override
  String sizeTerabytes(String size) {
    return '$size ТБ';
  }

  @override
  String get accessNeeded =>
      'Чтобы просматривать файлы, приложению нужен «Доступ ко всем файлам».';

  @override
  String get grantAccess => 'Дать доступ';

  @override
  String get folderNamesTitle => 'Папки для ваших файлов';

  @override
  String get folderNamesExplanation =>
      'Уборка раскладывает файлы по этим папкам в корне хранилища. Названия останутся прежними, даже если позже сменить язык.';

  @override
  String get folderNamesConfirm => 'Подтвердить';
}
