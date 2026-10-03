import 'package:meta/meta.dart';

/// What a file source can do. The planner only produces operations that the
/// source supports.
@immutable
final class SourceCapabilities {
  const SourceCapabilities({
    this.canMove = false,
    this.canMkdir = false,
    this.canQuarantine = false,
    this.quarantineRestorable = false,
    this.canAddToAlbum = false,
    this.providesCapturedAt = false,
    this.systemPurgesQuarantine = false,
  });

  /// No capabilities at all.
  static const SourceCapabilities none = SourceCapabilities();

  /// Files can be moved within the source.
  final bool canMove;

  /// Folders can be created.
  final bool canMkdir;

  /// Files can be put into quarantine.
  final bool canQuarantine;

  /// Quarantined files can be restored programmatically.
  final bool quarantineRestorable;

  /// Files can be added to an album (iOS Photos).
  final bool canAddToAlbum;

  /// The source reports the capture date cheaply.
  final bool providesCapturedAt;

  /// The quarantine is a system trash that empties itself (Android): the
  /// app does not purge it.
  final bool systemPurgesQuarantine;

  @override
  bool operator ==(Object other) =>
      other is SourceCapabilities &&
      other.canMove == canMove &&
      other.canMkdir == canMkdir &&
      other.canQuarantine == canQuarantine &&
      other.quarantineRestorable == quarantineRestorable &&
      other.canAddToAlbum == canAddToAlbum &&
      other.providesCapturedAt == providesCapturedAt &&
      other.systemPurgesQuarantine == systemPurgesQuarantine;

  @override
  int get hashCode => Object.hash(
    canMove,
    canMkdir,
    canQuarantine,
    quarantineRestorable,
    canAddToAlbum,
    providesCapturedAt,
    systemPurgesQuarantine,
  );

  @override
  String toString() =>
      'SourceCapabilities(canMove: $canMove, canMkdir: $canMkdir, '
      'canQuarantine: $canQuarantine, '
      'quarantineRestorable: $quarantineRestorable, '
      'canAddToAlbum: $canAddToAlbum, '
      'providesCapturedAt: $providesCapturedAt, '
      'systemPurgesQuarantine: $systemPurgesQuarantine)';
}
