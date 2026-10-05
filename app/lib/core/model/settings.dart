import 'package:file_organizer/core/internal/map_equals.dart';
import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/layout_folder_names.dart';
import 'package:meta/meta.dart';

/// App settings that the core uses.
@immutable
final class Settings {
  /// Throws [ArgumentError] if [quarantineRetention] is shorter than
  /// [minQuarantineRetention], if [layoutFolderNames] break the template
  /// rules (`checkLayoutFolderNames`) or if [uiLocale] is empty.
  Settings({
    this.quarantineRetention = defaultQuarantineRetention,
    Map<Category, String>? layoutFolderNames,
    this.uiLocale,
  }) : layoutFolderNames = layoutFolderNames == null
           ? null
           : Map.unmodifiable(layoutFolderNames) {
    if (quarantineRetention < minQuarantineRetention) {
      throw ArgumentError.value(
        quarantineRetention,
        'quarantineRetention',
        'must be at least $minQuarantineRetention',
      );
    }
    if (layoutFolderNames != null) {
      checkLayoutFolderNames(layoutFolderNames);
    }
    if (uiLocale != null && uiLocale!.isEmpty) {
      throw ArgumentError.value(uiLocale, 'uiLocale', 'use null for system');
    }
  }

  static const Duration defaultQuarantineRetention = Duration(days: 30);

  /// A misconfigured setting must not purge the quarantine right after a
  /// cleanup.
  static const Duration minQuarantineRetention = Duration(days: 1);

  /// How long quarantined files are kept before they are purged.
  final Duration quarantineRetention;

  /// Folder names of the layout template, fixed on the first start in the
  /// system language; `null` until then. Changing the UI language does not
  /// change them: that would create a second set of folders.
  final Map<Category, String>? layoutFolderNames;

  /// Language of the UI as a BCP 47 tag (`ru`, `en`); `null` follows the
  /// system.
  final String? uiLocale;

  /// A copy with the given fields changed. [uiLocale] uses a function so
  /// that it can be set back to `null` (the system language).
  Settings copyWith({
    Duration? quarantineRetention,
    Map<Category, String>? layoutFolderNames,
    String? Function()? uiLocale,
  }) => Settings(
    quarantineRetention: quarantineRetention ?? this.quarantineRetention,
    layoutFolderNames: layoutFolderNames ?? this.layoutFolderNames,
    uiLocale: uiLocale == null ? this.uiLocale : uiLocale(),
  );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.quarantineRetention == quarantineRetention &&
      mapEquals(other.layoutFolderNames, layoutFolderNames) &&
      other.uiLocale == uiLocale;

  @override
  int get hashCode =>
      Object.hash(quarantineRetention, mapHash(layoutFolderNames), uiLocale);

  @override
  String toString() =>
      'Settings(quarantineRetention: $quarantineRetention, '
      'layoutFolderNames: $layoutFolderNames, uiLocale: $uiLocale)';
}
