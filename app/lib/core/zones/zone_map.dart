import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:file_organizer/core/model/zone_override.dart';
import 'package:file_organizer/core/zones/zone_defaults.dart';
import 'package:file_organizer/core/zones/zone_reason.dart';
import 'package:meta/meta.dart';

/// Inputs of zone resolution that come from other parts of the app.
@immutable
final class ZoneConfig {
  const ZoneConfig({this.targetFolders = const {}, this.appFolders = const {}});

  /// Folders of the layout template (for example `Документы`, `Фото`).
  final Set<LogicalPath> targetFolders;

  /// Folders of this app inside the source, such as its quarantine.
  final Set<LogicalPath> appFolders;
}

/// Zones of the folders and files of one source.
///
/// Priority, strongest first:
/// 1. exclusions — built-in (hidden, development, system, app and project
///    folders) and the user's; inherited by subfolders and never
///    overridden;
/// 2. folders of the layout template and everything inside;
/// 3. the nearest zone the user set on the folder or a parent;
/// 4. defaults: files directly in the source root and in downloads or
///    desktop folders are chaos, messenger media folders are chaos with
///    all subfolders, everything else is organized.
///
/// Some files are excluded on their own (hidden, system, unfinished
/// downloads, lock files). Names are compared case-insensitively.
final class ZoneMap {
  /// Resolves zones for the source [sourceId].
  ///
  /// [files] are the indexed files of the source; they reveal project
  /// folders. Throws [ArgumentError] if an override or a file belongs to
  /// another source.
  ZoneMap({
    required this.sourceId,
    this.config = const ZoneConfig(),
    Iterable<ZoneOverride> overrides = const [],
    Iterable<FileEntry> files = const [],
  }) {
    for (final override in overrides) {
      if (override.sourceId != sourceId) {
        throw ArgumentError.value(override, 'overrides', 'other source');
      }
      _overrides[_lower(override.folder)] = override.zone;
    }
    for (final folder in config.targetFolders) {
      _targets.add(_lower(folder));
    }
    for (final folder in config.appFolders) {
      _appFolders.add(_lower(folder));
    }
    for (final file in files) {
      if (file.sourceId != sourceId) {
        throw ArgumentError.value(file, 'files', 'other source');
      }
      final name = file.name.toLowerCase();
      final marksProject =
          ZoneDefaults.projectMarkerFiles.contains(name) ||
          ZoneDefaults.projectMarkerExtensions.contains(file.extension);
      final folder = file.path.parent!;
      if (marksProject && !_isChaosByDefault(folder)) {
        _projectRoots[_lower(folder)] = folder;
      }
    }
  }

  final SourceId sourceId;

  final ZoneConfig config;

  final Map<String, Zone> _overrides = {};
  final Set<String> _targets = {};
  final Set<String> _appFolders = {};
  final Map<String, LogicalPath> _projectRoots = {};
  final Map<LogicalPath, ZoneDecision> _cache = {};

  /// Project folders found among the files, excluded as a whole.
  Set<LogicalPath> get projectRoots => Set.unmodifiable(_projectRoots.values);

  /// Whether the scan must not enter [folder]: the exclusions visible from
  /// the path alone (all but project folders).
  bool skipFolder(LogicalPath folder) =>
      _ancestorsOrSelf(folder).any((f) => _pathExclusion(f) != null);

  Zone zoneOfFolder(LogicalPath folder) => decideFolder(folder).zone;

  Zone zoneOfFile(LogicalPath file) => decideFile(file).zone;

  /// The zone of [file] and why.
  ZoneDecision decideFile(LogicalPath file) {
    if (file.isRoot) {
      throw ArgumentError.value(file, 'file', 'must not be the root');
    }
    final name = file.name.toLowerCase();
    if (name.startsWith('.')) {
      return ZoneDecision(ZoneReason.hiddenFile, file);
    }
    if (ZoneDefaults.systemFiles.contains(name)) {
      return ZoneDecision(ZoneReason.systemFile, file);
    }
    if (ZoneDefaults.incompleteExtensions.contains(file.extension) ||
        ZoneDefaults.lockFilePrefixes.any(name.startsWith)) {
      return ZoneDecision(ZoneReason.incompleteFile, file);
    }
    return decideFolder(file.parent!);
  }

  /// The zone of [folder] and why.
  ZoneDecision decideFolder(LogicalPath folder) =>
      _cache[folder] ??= _decideFolder(folder);

  ZoneDecision _decideFolder(LogicalPath folder) {
    final chain = _ancestorsOrSelf(folder);

    // 1. Exclusions, outermost first.
    for (final f in chain) {
      final reason =
          _pathExclusion(f) ??
          (_projectRoots.containsKey(_lower(f))
              ? ZoneReason.projectFolder
              : null);
      if (reason != null) {
        return ZoneDecision(reason, f);
      }
    }

    // 2. Template folders.
    for (final f in chain) {
      if (_targets.contains(_lower(f))) {
        return ZoneDecision(ZoneReason.templateFolder, f);
      }
    }

    // 3. The nearest user zone.
    for (final f in chain.reversed) {
      switch (_overrides[_lower(f)]) {
        case Zone.chaos:
          return ZoneDecision(ZoneReason.userChaos, f);
        case Zone.organized:
          return ZoneDecision(ZoneReason.userOrganized, f);
        case Zone.excluded || Zone.target || null:
          break;
      }
    }

    // 4. Defaults.
    for (final f in chain) {
      if (ZoneDefaults.messengerMediaFolders.contains(_lower(f))) {
        return ZoneDecision(ZoneReason.messengerMedia, f);
      }
    }
    final flat = _flatChaosReason(folder);
    if (flat != null) {
      return ZoneDecision(flat, folder);
    }
    return ZoneDecision(ZoneReason.notAChaosFolder, folder);
  }

  /// Exclusions visible from the path of [folder] itself (not its parents).
  ZoneReason? _pathExclusion(LogicalPath folder) {
    if (folder.isRoot) {
      return _overrides[''] == Zone.excluded ? ZoneReason.userExcluded : null;
    }
    final name = folder.name.toLowerCase();
    final path = _lower(folder);
    if (name.startsWith('.')) {
      return ZoneReason.hiddenFolder;
    }
    if (ZoneDefaults.developmentFolders.contains(name) ||
        ZoneDefaults.developmentFolderSuffixes.any(name.endsWith)) {
      return ZoneReason.developmentFolder;
    }
    if (ZoneDefaults.systemFoldersAnywhere.contains(name) ||
        ZoneDefaults.systemFoldersAtRoot.contains(path)) {
      return ZoneReason.systemFolder;
    }
    if (_appFolders.contains(path)) {
      return ZoneReason.appFolder;
    }
    if (_overrides[path] == Zone.excluded) {
      return ZoneReason.userExcluded;
    }
    return null;
  }

  /// Default chaos that covers only the files directly in [folder].
  ZoneReason? _flatChaosReason(LogicalPath folder) {
    if (folder.isRoot) {
      return ZoneReason.sourceRoot;
    }
    if (_isDownloadsOrDesktop(folder)) {
      return ZoneReason.downloadsOrDesktop;
    }
    final parent = folder.parent!;
    if (_isDownloadsOrDesktop(parent) &&
        ZoneDefaults.messengerDownloadFolders.contains(
          folder.name.toLowerCase(),
        )) {
      return ZoneReason.messengerDownloads;
    }
    return null;
  }

  bool _isDownloadsOrDesktop(LogicalPath folder) =>
      !folder.isRoot &&
      folder.parent!.isRoot &&
      ZoneDefaults.downloadsAndDesktop.contains(folder.name.toLowerCase());

  /// Whether [folder] is chaos by default rules alone; a stray build file
  /// there does not make it a project.
  bool _isChaosByDefault(LogicalPath folder) =>
      _flatChaosReason(folder) != null ||
      _ancestorsOrSelf(folder)
          .any((f) => ZoneDefaults.messengerMediaFolders.contains(_lower(f)));

  /// The root, then each folder down to [folder].
  static List<LogicalPath> _ancestorsOrSelf(LogicalPath folder) {
    final chain = <LogicalPath>[];
    for (LogicalPath? f = folder; f != null; f = f.parent) {
      chain.add(f);
    }
    return chain.reversed.toList();
  }

  static String _lower(LogicalPath path) => path.value.toLowerCase();
}
