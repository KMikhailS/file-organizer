import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/l10n/app_localizations.dart';

/// The name of [source] in the user's language. The shared storage is
/// named by its kind: the name saved with it is in the language of the
/// first start.
String sourceName(AppLocalizations l, Source source) => switch (source.kind) {
  SourceKind.androidFullStorage => l.internalStorage,
  SourceKind.desktopFolder ||
  SourceKind.androidSafTree ||
  SourceKind.androidMediaStore ||
  SourceKind.iosPhotos ||
  SourceKind.iosFolder => source.displayName,
};
