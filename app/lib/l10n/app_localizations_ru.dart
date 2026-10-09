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
  String get grantAccess => 'Дать доступ';

  @override
  String get folderNamesTitle => 'Папки для ваших файлов';

  @override
  String get folderNamesExplanation =>
      'Уборка раскладывает файлы по этим папкам в корне хранилища. Названия останутся прежними, даже если позже сменить язык.';

  @override
  String get folderNamesConfirm => 'Подтвердить';

  @override
  String get startupFailedTitle => 'Не удалось запустить приложение';

  @override
  String startupFailedDetails(String reason) {
    return 'Подробности: $reason';
  }

  @override
  String get tryAgain => 'Повторить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get introTitle => 'Порядок в ваших файлах';

  @override
  String get introText =>
      'Приложение находит дубли и раскладывает по папкам файлы из «Загрузок», мессенджеров и других захламлённых мест.';

  @override
  String get introPlanTitle => 'Сначала — план';

  @override
  String get introPlanText =>
      'Ничего не меняется, пока вы не просмотрите план и не примените его.';

  @override
  String get introQuarantineTitle => 'Ничего не удаляется';

  @override
  String get introQuarantineText =>
      'Лишние копии попадают в карантин, и их можно вернуть.';

  @override
  String get introUndoTitle => 'Всё можно откатить';

  @override
  String get introUndoText => 'Откат возвращает каждый файл на прежнее место.';

  @override
  String get accessTitle => 'Доступ к файлам';

  @override
  String get accessText =>
      'Чтобы находить дубли и раскладывать файлы, приложению нужен «Доступ ко всем файлам». Android откроет настройки: включите переключатель и вернитесь.';

  @override
  String get accessNotGranted =>
      'Доступ пока не выдан. Без него приложение не может просматривать файлы.';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsText =>
      'Уборка продолжается, даже если выйти из приложения. Уведомление показывает, как она идёт.';

  @override
  String get allowNotifications => 'Разрешить уведомления';

  @override
  String get notificationsDenied =>
      'Уведомления выключены. Уборка всё равно пройдёт, но её ход не будет виден вне приложения.';

  @override
  String get continueWithoutNotifications => 'Продолжить без них';

  @override
  String get categoryDocuments => 'Документы';

  @override
  String get categoryPhotos => 'Фото';

  @override
  String get categoryVideos => 'Видео';

  @override
  String get categoryScreenshots => 'Скриншоты';

  @override
  String get categoryMusic => 'Музыка';

  @override
  String get categoryArchives => 'Архивы';

  @override
  String get categoryInstallers => 'Установщики (APK)';

  @override
  String get categoryOther => 'Другие файлы';

  @override
  String get folderNameEmpty => 'Введите название';

  @override
  String folderNameTooLong(int max) {
    return 'Не больше $max символов';
  }

  @override
  String folderNameForbidden(String characters) {
    return 'В названии не может быть $characters';
  }

  @override
  String get folderNameLeadingDot => 'Название не может начинаться с точки';

  @override
  String get folderNameDuplicate => 'Такое название уже есть';

  @override
  String get cleanUpButton => 'Навести порядок';

  @override
  String get accessRevokedTitle => 'Нет доступа к файлам';

  @override
  String get accessRevokedText =>
      'Выдайте доступ снова, чтобы навести порядок.';

  @override
  String get lastCleanupNone => 'Уборок ещё не было';

  @override
  String lastCleanupTitle(String date) {
    return 'Последняя уборка: $date';
  }

  @override
  String get sessionCompleted => 'Выполнена';

  @override
  String get sessionFailed => 'Завершена с ошибками';

  @override
  String get sessionCancelled => 'Остановлена';

  @override
  String get sessionReverted => 'Отменена: всё возвращено';

  @override
  String get sessionPartiallyReverted => 'Отменена частично';

  @override
  String lastCleanupDone(int done, int total) {
    return 'Выполнено операций: $done из $total';
  }

  @override
  String lastCleanupProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Пропущено или с ошибкой $count операции',
      many: 'Пропущено или с ошибкой $count операций',
      few: 'Пропущены или с ошибкой $count операции',
      one: 'Пропущена или с ошибкой $count операция',
    );
    return '$_temp0';
  }

  @override
  String lastCleanupReverted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отменено $count операции',
      many: 'Отменено $count операций',
      few: 'Отменены $count операции',
      one: 'Отменена $count операция',
    );
    return '$_temp0';
  }

  @override
  String lastCleanupFreed(String size) {
    return 'Освобождено: $size';
  }
}
