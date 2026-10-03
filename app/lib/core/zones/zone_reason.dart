import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:meta/meta.dart';

/// Why a folder or file is in its zone. Each reason belongs to one zone.
enum ZoneReason {
  // Excluded: never scanned (where visible from the path) and never touched.

  /// A folder whose name starts with a dot.
  hiddenFolder(Zone.excluded),

  /// A development folder such as `node_modules` or `build`.
  developmentFolder(Zone.excluded),

  /// A system folder such as `Android/data`, `AppData` or `Program Files`.
  systemFolder(Zone.excluded),

  /// A folder of this app, such as its quarantine.
  appFolder(Zone.excluded),

  /// A project folder: it contains a build file such as `pubspec.yaml`.
  projectFolder(Zone.excluded),

  /// The user excluded the folder.
  userExcluded(Zone.excluded),

  /// A file whose name starts with a dot.
  hiddenFile(Zone.excluded),

  /// A system file such as `desktop.ini` or `Thumbs.db`.
  systemFile(Zone.excluded),

  /// An unfinished download, a temporary or a lock file; moving it would
  /// break the program writing it.
  incompleteFile(Zone.excluded),

  // Target.

  /// A folder of the layout template, or inside one.
  templateFolder(Zone.target),

  // Set by the user.

  /// The user marked the folder (or a parent) for cleaning.
  userChaos(Zone.chaos),

  /// The user marked the folder (or a parent) as organized.
  userOrganized(Zone.organized),

  // Defaults.

  /// Files directly in the source root.
  sourceRoot(Zone.chaos),

  /// Files directly in a downloads or desktop folder at the source root.
  downloadsOrDesktop(Zone.chaos),

  /// Files directly in a messenger downloads folder inside a downloads
  /// folder (`Downloads/Telegram Desktop`).
  messengerDownloads(Zone.chaos),

  /// A messenger media folder, with all its subfolders.
  messengerMedia(Zone.chaos),

  /// Any other folder, including subfolders of downloads and desktop
  /// folders: left as the user arranged it.
  notAChaosFolder(Zone.organized);

  const ZoneReason(this.zone);

  final Zone zone;
}

/// The zone of a folder or file and why.
@immutable
final class ZoneDecision {
  const ZoneDecision(this.reason, this.decidedBy);

  final ZoneReason reason;

  /// The folder (or file) whose rule decided: the path itself or a parent.
  final LogicalPath decidedBy;

  Zone get zone => reason.zone;

  @override
  bool operator ==(Object other) =>
      other is ZoneDecision &&
      other.reason == reason &&
      other.decidedBy == decidedBy;

  @override
  int get hashCode => Object.hash(reason, decidedBy);

  @override
  String toString() =>
      'ZoneDecision(${zone.name}: ${reason.name} at $decidedBy)';
}
