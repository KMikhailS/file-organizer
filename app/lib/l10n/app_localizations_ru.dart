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
  String get sessionReverted => 'Отменена';

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

  @override
  String get cancel => 'Отменить';

  @override
  String get cancelling => 'Отменяется…';

  @override
  String get back => 'Назад';

  @override
  String get progressCanLeave =>
      'Можно выйти из приложения — работа продолжится.';

  @override
  String progressStorageOf(int index, int count) {
    return 'Хранилище $index из $count';
  }

  @override
  String get planFailedTitle => 'Не удалось составить план';

  @override
  String get planTitle => 'План уборки';

  @override
  String planSummaryFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Будет разобрано $count файла',
      many: 'Будет разобрано $count файлов',
      few: 'Будет разобрано $count файла',
      one: 'Будет разобран $count файл',
    );
    return '$_temp0';
  }

  @override
  String planSummaryFreed(String size) {
    return 'Освободится $size';
  }

  @override
  String get planNothingSelected => 'Ничего не выбрано';

  @override
  String get planEmptyTitle => 'Всё уже в порядке';

  @override
  String get planEmptyText => 'Сейчас нечего разбирать.';

  @override
  String groupDuplicates(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Дубли: $count файла, $size',
      many: 'Дубли: $count файлов, $size',
      few: 'Дубли: $count файла, $size',
      one: 'Дубли: $count файл, $size',
    );
    return '$_temp0';
  }

  @override
  String groupMoveTo(String folder, int count) {
    return 'В $folder: $count';
  }

  @override
  String get groupDuplicatesHint =>
      'Лишние копии уходят в карантин; у каждой указано, какая копия остаётся.';

  @override
  String fileFrom(String folder) {
    return 'Из $folder';
  }

  @override
  String get applyButton => 'Применить';

  @override
  String get declineButton => 'Отказаться';

  @override
  String get showFiles => 'Показать файлы';

  @override
  String get hideFiles => 'Скрыть файлы';

  @override
  String unresolvedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не разобрано $count файла',
      many: 'Не разобрано $count файлов',
      few: 'Не разобрано $count файла',
      one: 'Не разобран $count файл',
    );
    return '$_temp0';
  }

  @override
  String get unresolvedText =>
      'Приложение не уверено, куда их положить. Они остаются на месте.';

  @override
  String untouchedCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count копии в ваших папках — не трогаем',
      many: 'Ещё $count копий в ваших папках — не трогаем',
      few: 'Ещё $count копии в ваших папках — не трогаем',
      one: 'Ещё $count копия в ваших папках — не трогаем',
    );
    return '$_temp0';
  }

  @override
  String get warningsTitle => 'Не всё удалось проверить';

  @override
  String warningInaccessible(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не удалось прочитать $count папки',
      many: 'Не удалось прочитать $count папок',
      few: 'Не удалось прочитать $count папки',
      one: 'Не удалось прочитать $count папку',
    );
    return '$_temp0';
  }

  @override
  String warningUnhashed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Не удалось прочитать $count файла — неизвестно, есть ли у них дубли',
      many:
          'Не удалось прочитать $count файлов — неизвестно, есть ли у них дубли',
      few:
          'Не удалось прочитать $count файла — неизвестно, есть ли у них дубли',
      one:
          'Не удалось прочитать $count файл — неизвестно, есть ли у него дубли',
    );
    return '$_temp0';
  }

  @override
  String warningUnavailableSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хранилища были недоступны',
      many: '$count хранилищ были недоступны',
      few: '$count хранилища были недоступны',
      one: '$count хранилище было недоступно',
    );
    return '$_temp0';
  }

  @override
  String get resultCompleted => 'Уборка завершена';

  @override
  String get resultCancelled => 'Уборка остановлена';

  @override
  String get resultReverted => 'Уборка отменена';

  @override
  String get resultPartiallyReverted => 'Уборка отменена частично';

  @override
  String countDone(int count) {
    return 'Выполнено: $count';
  }

  @override
  String countSkipped(int count) {
    return 'Пропущено: $count';
  }

  @override
  String countFailed(int count) {
    return 'Ошибок: $count';
  }

  @override
  String countReverted(int count) {
    return 'Возвращено: $count';
  }

  @override
  String countNotReverted(int count) {
    return 'Не возвращено: $count';
  }

  @override
  String get problemsTitle => 'Что не получилось';

  @override
  String get needsAttention => 'Требует внимания';

  @override
  String get undoCleanupButton => 'Отменить уборку';

  @override
  String get closeButton => 'Готово';

  @override
  String get undoConfirmTitle => 'Вернуть файлы?';

  @override
  String get undoConfirmAll =>
      'Все файлы этой уборки вернутся на прежние места.';

  @override
  String undoConfirmFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла вернутся на прежние места.',
      many: '$count файлов вернутся на прежние места.',
      few: '$count файла вернутся на прежние места.',
      one: '$count файл вернётся на прежнее место.',
    );
    return '$_temp0';
  }

  @override
  String get undoConfirmYes => 'Вернуть';

  @override
  String get interruptedTitle => 'Последняя уборка была прервана';

  @override
  String get interruptedText =>
      'Приложение остановилось посреди уборки. Каждая начатая операция проверена: сделанное осталось на месте, ничего не перезаписано.';

  @override
  String interruptedOperations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Разобрано $count операции',
      many: 'Разобрано $count операций',
      few: 'Разобрано $count операции',
      one: 'Разобрана $count операция',
    );
    return '$_temp0';
  }

  @override
  String interruptedUnavailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уборки ждут, когда хранилище снова станет доступно',
      many: '$count уборок ждут, когда хранилище снова станет доступно',
      few: '$count уборки ждут, когда хранилище снова станет доступно',
      one: '$count уборка ждёт, когда хранилище снова станет доступно',
    );
    return '$_temp0';
  }

  @override
  String get interruptedFinish => 'Доделать';

  @override
  String get interruptedUndo => 'Откатить';

  @override
  String get interruptedLater => 'Не сейчас';

  @override
  String get historyTitle => 'История';

  @override
  String get sessionInterrupted => 'Прервана';

  @override
  String sessionTitle(String date) {
    return 'Уборка $date';
  }

  @override
  String get undoWholeButton => 'Отменить всю уборку';

  @override
  String get undoGroupButton => 'Вернуть эту группу';

  @override
  String get undoFileButton => 'Вернуть';

  @override
  String get purgedMark => 'Карантин очищен — откат невозможен';

  @override
  String get fileDone => 'Сделано';

  @override
  String get fileReverted => 'Возвращён';

  @override
  String get nothingToUndo => 'Откатывать нечего';

  @override
  String groupFiles(int count) {
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
  String get groupDuplicatesTitle => 'Дубли';

  @override
  String groupMoveTitle(String folder) {
    return 'В $folder';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionFolders => 'Папки';

  @override
  String get foldersHint =>
      'Пометьте папку, чтобы изменить, что уборка с ней делает.';

  @override
  String get zoneChaos => 'Убирать';

  @override
  String get zoneOrganized => 'Не трогать';

  @override
  String get zoneExcluded => 'Исключить';

  @override
  String get zoneChaosHint => 'Файлы отсюда раскладываются по папкам шаблона';

  @override
  String get zoneOrganizedHint => 'Файлы здесь никогда не перемещаются';

  @override
  String get zoneExcludedHint => 'Папка даже не просматривается';

  @override
  String get addFolderMark => 'Пометить папку';

  @override
  String get noFolderMarks => 'Пометок пока нет';

  @override
  String chooseZoneTitle(String folder) {
    return 'Что делать с $folder?';
  }

  @override
  String chaosWarning(String folder) {
    return 'Все файлы в $folder и вложенных папках будут предлагаться к раскладке по папкам шаблона. Ничего не переместится, пока вы не примените план.';
  }

  @override
  String get continueButton => 'Продолжить';

  @override
  String get removeMark => 'Снять пометку';

  @override
  String get storageRoot => 'Всё хранилище';

  @override
  String get chooseFolderTitle => 'Выберите папку';

  @override
  String get chooseThisFolder => 'Выбрать эту папку';

  @override
  String get noSubfolders => 'Внутри нет папок';

  @override
  String get folderUnreadable => 'Эту папку не удаётся прочитать';

  @override
  String get sectionRules => 'Ваши правила';

  @override
  String get rulesHint =>
      'Ваши правила действуют раньше встроенных, сверху вниз.';

  @override
  String get addRule => 'Добавить правило';

  @override
  String get noRules => 'Правил пока нет';

  @override
  String get ruleTitle => 'Правило';

  @override
  String get ruleExtensions => 'Расширения';

  @override
  String get ruleExtensionsHint => 'pdf, docx';

  @override
  String get ruleNameContains => 'Имя содержит';

  @override
  String get ruleFolder => 'В папке';

  @override
  String get ruleAnyFolder => 'Где угодно';

  @override
  String get ruleTarget => 'Куда класть';

  @override
  String get ruleKeepInPlace => 'Оставлять на месте';

  @override
  String get ruleNeedsCondition => 'Задайте хотя бы одно условие';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get deleteButton => 'Удалить';

  @override
  String get moveUp => 'Выше';

  @override
  String get moveDown => 'Ниже';

  @override
  String ruleSummaryName(String text) {
    return 'имя содержит «$text»';
  }

  @override
  String ruleSummaryFolder(String folder) {
    return 'в $folder';
  }

  @override
  String ruleSummary(String conditions, String target) {
    return '$conditions → $target';
  }

  @override
  String get sectionQuarantine => 'Карантин';

  @override
  String get quarantineHint =>
      'Лишние копии хранятся какое-то время, чтобы уборку можно было отменить, затем удаляются навсегда.';

  @override
  String retentionDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String retentionShorterWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Копии старше $count дня удалятся навсегда при следующем запуске приложения, вернуть их будет нельзя.',
      many:
          'Копии старше $count дней удалятся навсегда при следующем запуске приложения, вернуть их будет нельзя.',
      few:
          'Копии старше $count дней удалятся навсегда при следующем запуске приложения, вернуть их будет нельзя.',
      one:
          'Копии старше $count дня удалятся навсегда при следующем запуске приложения, вернуть их будет нельзя.',
    );
    return '$_temp0';
  }

  @override
  String get sectionLanguage => 'Язык';

  @override
  String get languageSystem => 'Как в телефоне';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get sectionPermissions => 'Разрешения';

  @override
  String get permissionAllFiles => 'Доступ ко всем файлам';

  @override
  String get permissionGranted => 'Выдан';

  @override
  String get permissionNotGranted => 'Не выдан';

  @override
  String get notificationsOn => 'Включены';

  @override
  String get notificationsOff => 'Выключены';

  @override
  String get templateFolderNote =>
      'Это папка шаблона: уборка ничего в ней не перемещает, поэтому пометка здесь не действует.';
}
