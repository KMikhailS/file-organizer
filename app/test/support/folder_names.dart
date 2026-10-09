import 'package:file_organizer/core/model/category.dart';

/// The folder names of the template the user approved for each language
/// (`docs/stage2_android.md`, 5.15).
const Map<Category, String> englishNames = {
  Category.documents: 'Documents',
  Category.photos: 'Photos',
  Category.videos: 'Videos',
  Category.screenshots: 'Screenshots',
  Category.music: 'Music',
  Category.archives: 'Archives',
  Category.installers: 'Installers',
  Category.other: 'Other',
};

const Map<Category, String> russianNames = {
  Category.documents: 'Документы',
  Category.photos: 'Фото',
  Category.videos: 'Видео',
  Category.screenshots: 'Скриншоты',
  Category.music: 'Музыка',
  Category.archives: 'Архивы',
  Category.installers: 'Установщики',
  Category.other: 'Другое',
};
