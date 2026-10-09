import 'package:file_organizer/core/layout/layout.dart';
import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/data/db/app_database.dart';
import 'package:file_organizer/data/repositories/drift_repositories.dart';
import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/app_texts.dart';
import 'package:file_organizer/state/foreground_binding.dart';
import 'package:file_organizer/state/open_sources.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The platform services. `main.dart` overrides it with
/// `AppServices.android()`; tests with fakes.
final appServicesProvider = Provider<AppServices>(
  (ref) => throw UnimplementedError('override appServicesProvider'),
);

/// Makes the texts of the state layer in a language. `main.dart` overrides
/// it with the UI's localization; tests with fakes.
final appTextsFactoryProvider = Provider<AppTextsFactory>(
  (ref) => throw UnimplementedError('override appTextsFactoryProvider'),
);

/// The languages of the system, most preferred first (BCP 47 tags).
/// `main.dart` sets the start value, the UI reports changes.
final systemLanguagesProvider = NotifierProvider<SystemLanguages, List<String>>(
  SystemLanguages.new,
);

final class SystemLanguages extends Notifier<List<String>> {
  SystemLanguages([List<String> initial = const []])
    : _initial = List.unmodifiable(initial);

  final List<String> _initial;

  @override
  List<String> build() => _initial;

  void changed(List<String> languages) => state = List.unmodifiable(languages);
}

/// The language chosen in the settings (`Settings.uiLocale`); `null`
/// follows the system. The start loads it from the settings.
final uiLocaleProvider = NotifierProvider<UiLocale, String?>(UiLocale.new);

final class UiLocale extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? locale) => state = locale;
}

/// The languages the texts follow: the chosen one, then the system's.
final languagesProvider = Provider<List<String>>(
  (ref) => [
    ?ref.watch(uiLocaleProvider),
    ...ref.watch(systemLanguagesProvider),
  ],
);

/// The texts of the state layer in the current language.
final appTextsProvider = Provider<AppTexts>(
  (ref) => ref.watch(appTextsFactoryProvider)(ref.watch(languagesProvider)),
);

/// The folder names of the template the user confirmed on the first start
/// (`Settings.layoutFolderNames`); `null` until the start loads them.
final layoutFolderNamesProvider =
    NotifierProvider<LayoutFolderNames, Map<Category, String>?>(
      LayoutFolderNames.new,
    );

final class LayoutFolderNames extends Notifier<Map<Category, String>?> {
  @override
  Map<Category, String>? build() => null;

  /// Sets the names once. They never change afterwards: other names would
  /// create a second set of folders (`docs/stage2_android.md`, 3.3).
  void fix(Map<Category, String> names) {
    final current = state;
    if (current == null) {
      state = Map.unmodifiable(names);
    } else if (current.length != names.length ||
        current.entries.any((e) => names[e.key] != e.value)) {
      throw StateError('the folder names are fixed already');
    }
  }
}

/// The folder names proposed on the first start, in the current language.
final proposedFolderNamesProvider = Provider<Map<Category, String>>(
  (ref) => ref.watch(appTextsProvider).folderNames,
);

/// The database, open for the whole run.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = ref.watch(appServicesProvider).openDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoriesProvider = Provider<WorkflowRepositories>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkflowRepositories(
    sources: DriftSourceRepository(db),
    rules: DriftRuleRepository(db),
    settings: DriftSettingsRepository(db),
    index: DriftFileIndexRepository(db),
    checkpoints: DriftScanCheckpointRepository(db),
    sessions: DriftSessionRepository(db),
    journal: DriftOperationJournal(db),
  );
});

/// The file sources opened at start-up.
final openSourcesProvider = Provider<OpenSources>((ref) => OpenSources());

/// The cleanup workflow. It lives as long as the Flutter engine, which the
/// Android side keeps in its cache, so closing the screen does not stop a
/// cleanup. It needs the confirmed folder names: the start reads it only
/// after [layoutFolderNamesProvider] is set.
final workflowProvider = Provider<CleanupWorkflow>((ref) {
  final services = ref.watch(appServicesProvider);
  final sources = ref.watch(openSourcesProvider);
  final folderNames =
      ref.watch(layoutFolderNamesProvider) ??
      (throw StateError('the folder names are not confirmed yet'));
  return CleanupWorkflow(
    repositories: ref.watch(repositoriesProvider),
    fileSources: sources.lookup,
    template: LayoutTemplate(
      folderNames: folderNames,
      // The year folder of the user's time zone, not UTC.
      yearOf: (utc) => utc.toLocal().year,
    ),
    clock: services.clock,
    ids: services.ids,
    // Read, not watched: a change of language must not replace the workflow
    // (and lose a running cleanup); the label follows it after a restart.
    restoredLabel: ref.read(appTextsProvider).restoredLabel,
  );
});

/// The state of the workflow: the current one first, then every change.
final workflowStateProvider = StreamProvider<WorkflowState>(
  (ref) => ref.watch(workflowProvider).states,
);

/// The foreground service following the workflow; attached at start-up.
final foregroundBindingProvider = Provider<ForegroundBinding>((ref) {
  final binding = ForegroundBinding(
    native: ref.watch(appServicesProvider).native,
    workflow: ref.watch(workflowProvider),
    // The notification follows a change of language at once.
    texts: () => ref.read(appTextsProvider),
  );
  ref.onDispose(binding.dispose);
  return binding;
});
