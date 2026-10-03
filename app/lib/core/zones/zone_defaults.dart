/// Built-in zone rules. Names and paths are lower case and compared
/// case-insensitively. Exclusions cannot be overridden by the user.
abstract final class ZoneDefaults {
  /// Development folders, excluded wherever they appear.
  static const Set<String> developmentFolders = {
    'node_modules',
    'bower_components',
    '__pycache__',
    'venv',
    'build',
    'target',
    'pods',
    'deriveddata',
  };

  /// Suffixes of development folder names (Xcode bundles).
  static const Set<String> developmentFolderSuffixes = {
    '.xcodeproj',
    '.xcworkspace',
  };

  /// System folders, excluded wherever they appear.
  static const Set<String> systemFoldersAnywhere = {
    'appdata',
    r'$recycle.bin',
    'system volume information',
    'lost.dir',
    'lost+found',
  };

  /// System folders, excluded at these paths from the source root.
  static const Set<String> systemFoldersAtRoot = {
    'android/data',
    'android/obb',
    'windows',
    'program files',
    'program files (x86)',
    'programdata',
    'library',
    'applications',
    'snap',
  };

  /// Files that mark their folder as a project, excluded as a whole.
  static const Set<String> projectMarkerFiles = {
    'pubspec.yaml',
    'package.json',
    'pom.xml',
    'build.gradle',
    'build.gradle.kts',
    'settings.gradle',
    'settings.gradle.kts',
    'cargo.toml',
    'go.mod',
    'cmakelists.txt',
    'makefile',
    'pyproject.toml',
    'setup.py',
    'composer.json',
    'gemfile',
  };

  /// Extensions of files that mark their folder as a project.
  static const Set<String> projectMarkerExtensions = {
    'sln',
    'csproj',
    'vcxproj',
  };

  /// Downloads and desktop folders at the source root, in common languages.
  /// Only files directly inside are cleaned.
  static const Set<String> downloadsAndDesktop = {
    'download',
    'downloads',
    'desktop',
    'загрузки',
    'рабочий стол',
    'téléchargements',
    'bureau',
    'descargas',
    'escritorio',
    'schreibtisch',
    'scaricati',
    'scrivania',
    'transferências',
    'área de trabalho',
  };

  /// Messenger download folders inside a downloads folder. Only files
  /// directly inside are cleaned (chat exports in subfolders stay).
  static const Set<String> messengerDownloadFolders = {'telegram desktop'};

  /// Messenger media folders (paths from the source root), cleaned with all
  /// their subfolders.
  static const Set<String> messengerMediaFolders = {
    'telegram',
    'android/media/org.telegram.messenger/telegram',
    'whatsapp/media',
    'android/media/com.whatsapp/whatsapp/media',
    'viber/media',
  };

  /// System files, excluded wherever they appear.
  static const Set<String> systemFiles = {'desktop.ini', 'thumbs.db', 'icon\r'};

  /// Extensions of unfinished downloads and temporary files.
  static const Set<String> incompleteExtensions = {
    'crdownload',
    'part',
    'partial',
    'download',
    'opdownload',
    'tmp',
  };

  /// Name prefixes of lock files (Microsoft Office).
  static const Set<String> lockFilePrefixes = {r'~$'};
}
