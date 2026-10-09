import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/root_screen.dart';
import 'package:file_organizer/ui/texts/localized_app_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app shell.
///
/// The language is resolved once, from `languagesProvider`, for the screens
/// and for the texts of the state layer (the notification), so both always
/// speak the same language.
class FileOrganizerApp extends ConsumerStatefulWidget {
  const FileOrganizerApp({super.key});

  @override
  ConsumerState<FileOrganizerApp> createState() => _FileOrganizerAppState();
}

class _FileOrganizerAppState extends ConsumerState<FileOrganizerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The user changed the language of the phone.
  @override
  void didChangeLocales(List<Locale>? locales) {
    ref.read(systemLanguagesProvider.notifier).changed(tagsOf(locales ?? []));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: resolveLanguage(ref.watch(languagesProvider)),
    home: const RootScreen(),
  );
}
