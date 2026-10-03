import 'package:file_organizer/core/model/source_capabilities.dart';

/// A desktop folder or Android full storage: everything except albums, own
/// quarantine folder.
const SourceCapabilities desktopCapabilities = SourceCapabilities(
  canMove: true,
  canMkdir: true,
  canQuarantine: true,
  quarantineRestorable: true,
);

/// Android MediaStore: moves within media folders, system trash with
/// programmatic restore that empties itself, cheap capture dates.
const SourceCapabilities androidMediaStoreCapabilities = SourceCapabilities(
  canMove: true,
  canMkdir: true,
  canQuarantine: true,
  quarantineRestorable: true,
  providesCapturedAt: true,
  systemPurgesQuarantine: true,
);

/// iOS Photos: no moves, no folders, no restorable trash; duplicates go to
/// an album.
const SourceCapabilities iosPhotosCapabilities = SourceCapabilities(
  canAddToAlbum: true,
  providesCapturedAt: true,
);
