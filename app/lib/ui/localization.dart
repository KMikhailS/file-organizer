import 'dart:ui' show PlatformDispatcher;

import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/texts/localized_app_texts.dart';
import 'package:flutter_riverpod/misc.dart';

/// What the state layer takes from the localization: its texts and the
/// languages of the system at start. `main.dart` passes these to the
/// `ProviderScope`; `FileOrganizerApp` reports later changes of the system
/// languages.
List<Override> localizationOverrides() => [
  appTextsFactoryProvider.overrideWithValue(LocalizedAppTexts.forLanguages),
  systemLanguagesProvider.overrideWith(
    () => SystemLanguages(tagsOf(PlatformDispatcher.instance.locales)),
  ),
];
