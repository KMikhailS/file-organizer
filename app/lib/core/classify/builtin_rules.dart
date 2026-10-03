import 'package:file_organizer/core/model/category.dart';

/// Built-in classification by extension (lower case, without the dot).
abstract final class BuiltinRules {
  static const Map<Category, Set<String>> extensions = {
    Category.documents: {
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', //
      'odp', 'rtf', 'txt', 'csv', 'epub', 'md', 'djvu', 'fb2', 'pages',
      'numbers', 'key',
    },
    Category.photos: {
      'jpg', 'jpeg', 'heic', 'heif', 'png', 'webp', 'gif', 'bmp', 'tif', //
      'tiff', 'cr2', 'cr3', 'nef', 'arw', 'dng', 'raf', 'orf', 'rw2',
    },
    Category.videos: {
      'mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v', '3gp', 'wmv', 'mts', //
    },
    Category.music: {
      'mp3', 'flac', 'm4a', 'wav', 'ogg', 'aac', 'opus', 'wma', 'alac', //
    },
    Category.archives: {'zip', 'rar', '7z', 'tar', 'gz', 'tgz', 'bz2', 'xz'},
    Category.installers: {
      'apk', 'apks', 'xapk', 'exe', 'msi', 'dmg', 'pkg', 'deb', 'rpm', //
      'appimage',
    },
    Category.other: {'torrent', 'ics', 'vcf', 'ttf', 'otf', 'gpx', 'kml'},
  };

  /// Extensions of images that can be screenshots.
  static const Set<String> screenshotExtensions = {
    'png', 'jpg', 'jpeg', 'webp', 'heic', 'heif', //
  };

  /// Lower-case name prefixes of screenshots.
  static const List<String> screenshotNamePrefixes = [
    'screenshot',
    'screen shot',
    'снимок экрана',
    'скриншот',
  ];

  /// Lower-case names of folders that hold screenshots.
  static const Set<String> screenshotFolders = {'screenshots', 'скриншоты'};

  /// MIME type families and the categories they agree with.
  static const Map<String, Set<Category>> mimeFamilies = {
    'image/': {Category.photos, Category.screenshots},
    'video/': {Category.videos},
    'audio/': {Category.music},
  };

  /// MIME types that say nothing about the content.
  static const Set<String> genericMimeTypes = {
    'application/octet-stream',
    'binary/octet-stream',
  };

  /// The category of [extension], or `null` if unknown.
  static Category? categoryOf(String extension) {
    for (final MapEntry(:key, :value) in extensions.entries) {
      if (value.contains(extension)) {
        return key;
      }
    }
    return null;
  }
}
