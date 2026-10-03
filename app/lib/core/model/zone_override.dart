import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:meta/meta.dart';

/// A zone the user set for a folder by hand. It applies to the folder and
/// everything inside, and takes priority over the default zones, but not
/// over default exclusions or the template's target folders.
@immutable
final class ZoneOverride {
  /// Throws [ArgumentError] for [Zone.target]: target folders come from the
  /// layout template only.
  ZoneOverride({
    required this.sourceId,
    required this.folder,
    required this.zone,
  }) {
    if (zone == Zone.target) {
      throw ArgumentError.value(
        zone,
        'zone',
        'target folders come from the template',
      );
    }
  }

  final SourceId sourceId;

  /// The marked folder; the root marks the whole source.
  final LogicalPath folder;

  /// [Zone.chaos], [Zone.organized] or [Zone.excluded].
  final Zone zone;

  @override
  bool operator ==(Object other) =>
      other is ZoneOverride &&
      other.sourceId == sourceId &&
      other.folder == folder &&
      other.zone == zone;

  @override
  int get hashCode => Object.hash(sourceId, folder, zone);

  @override
  String toString() => 'ZoneOverride($sourceId:$folder -> ${zone.name})';
}
