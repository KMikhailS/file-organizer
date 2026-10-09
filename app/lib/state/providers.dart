import 'package:file_organizer/core/layout/layout.dart';
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
/// cleanup.
final workflowProvider = Provider<CleanupWorkflow>((ref) {
  final services = ref.watch(appServicesProvider);
  final sources = ref.watch(openSourcesProvider);
  return CleanupWorkflow(
    repositories: ref.watch(repositoriesProvider),
    fileSources: sources.lookup,
    template: LayoutTemplate(
      folderNames: AppTexts.folderNames,
      // The year folder of the user's time zone, not UTC.
      yearOf: (utc) => utc.toLocal().year,
    ),
    clock: services.clock,
    ids: services.ids,
    restoredLabel: AppTexts.restoredLabel,
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
  );
  ref.onDispose(binding.dispose);
  return binding;
});
