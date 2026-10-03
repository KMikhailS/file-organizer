import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:meta/meta.dart';

/// Kind of a file source.
enum SourceKind {
  desktopFolder,
  androidFullStorage,
  androidSafTree,
  androidMediaStore,
  iosPhotos,
  iosFolder,
}

/// A place the app scans and cleans up. Operations never cross sources.
@immutable
final class Source {
  const Source({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.capabilities,
    required this.enabled,
  });

  final SourceId id;

  final SourceKind kind;

  /// Name shown in the UI.
  final String displayName;

  final SourceCapabilities capabilities;

  /// Whether the source takes part in cleanups.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is Source &&
      other.id == id &&
      other.kind == kind &&
      other.displayName == displayName &&
      other.capabilities == capabilities &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, kind, displayName, capabilities, enabled);

  @override
  String toString() =>
      'Source($id, $kind, "$displayName", enabled: $enabled, $capabilities)';
}
