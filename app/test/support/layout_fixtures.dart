import 'package:file_organizer/core/layout/layout.dart';
import 'package:file_organizer/core/model/model.dart';

/// Russian folder names, as the app's localization would pass them.
const Map<Category, String> russianFolderNames = {
  Category.documents: 'Документы',
  Category.photos: 'Фото',
  Category.videos: 'Видео',
  Category.screenshots: 'Скриншоты',
  Category.music: 'Музыка',
  Category.archives: 'Архивы',
  Category.installers: 'Установщики',
  Category.other: 'Прочее',
};

/// The template with Russian names at the source root, years in UTC.
LayoutTemplate russianTemplate({
  LogicalPath root = LogicalPath.root,
  int Function(DateTime utc)? yearOf,
}) =>
    LayoutTemplate(folderNames: russianFolderNames, root: root, yearOf: yearOf);
