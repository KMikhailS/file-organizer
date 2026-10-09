import 'package:file_organizer/core/model/category.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts the app (`docs/stage2_android.md`, section 7): database and
/// settings → "All files access" → the shared storage source (created on
/// the first start) is opened → the folder names of the template (fixed on
/// the first start, 3.3) → the workflow recovers interrupted sessions and
/// purges the expired quarantine → the foreground service follows the
/// workflow.
///
/// Without access the workflow is not initialized: recovery needs the
/// source. [requestAccess] or a later [start] picks up from there; on the
/// first start [confirmFolderNames] does.
final class AppController extends Notifier<AppStatus> {
  /// The id of the shared storage source.
  static const SourceId storageId = SourceId('primary-storage');

  bool _initialized = false;
  Future<void>? _starting;

  @override
  AppStatus build() => const AppStarting();

  /// Runs the start; again after the user may have granted access (for
  /// example on returning to the app). Does nothing once ready.
  Future<void> start() =>
      _starting ??= _start().whenComplete(() => _starting = null);

  /// Asks for "All files access" on the system screen, then starts.
  Future<void> requestAccess() async {
    await ref.read(appServicesProvider).native.requestAllFilesAccess();
    await start();
  }

  /// Fixes the folder names of the template on the first start (status
  /// [FolderNamesNeeded]), then goes on with the start. Throws
  /// [StateError] in any other status and [ArgumentError] if [names] break
  /// the template rules (`checkLayoutFolderNames`); nothing is saved then.
  Future<void> confirmFolderNames(Map<Category, String> names) async {
    // A start in progress settles the status first.
    await _starting;
    if (state is! FolderNamesNeeded) {
      throw StateError('the folder names are not expected now: $state');
    }
    // Taken before the first await: a second confirmation (a double tap)
    // fails instead of saving other names over these.
    state = const AppStarting();
    final settings = ref.read(repositoriesProvider).settings;
    try {
      final current = await settings.load();
      // Only the first confirmation is saved: the names never change.
      if (current.layoutFolderNames == null) {
        await settings.save(current.copyWith(layoutFolderNames: names));
      }
    } on Object {
      state = const FolderNamesNeeded();
      rethrow;
    }
    await start();
  }

  Future<void> _start() async {
    if (state is AppReady) {
      return;
    }
    final services = ref.read(appServicesProvider);
    final native = services.native;
    try {
      final repositories = ref.read(repositoriesProvider);
      final settings = await repositories.settings.load();
      ref.read(uiLocaleProvider.notifier).set(settings.uiLocale);
      if (await native.hasAllFilesAccess() != const NativeOk(true)) {
        state = const AccessNeeded();
        return;
      }
      final root = switch (await native.primaryStorageRoot()) {
        NativeOk(:final value?) => value,
        NativeOk() => null,
        NativeFailed(:final code) => throw StateError('storage root: $code'),
      };
      if (root == null) {
        state = const StartupFailed('the shared storage is not mounted');
        return;
      }

      final known = await repositories.sources.byId(storageId);
      var source =
          known ??
          Source(
            id: storageId,
            kind: SourceKind.androidFullStorage,
            // Not shown: the UI names the source by its kind, in the
            // current language.
            displayName: 'Internal storage',
            location: root,
            capabilities: SourceCapabilities.none,
            enabled: true,
          );
      if (source.location != root) {
        source = _withLocation(source, root);
      }
      final files = await services.openSource(source);
      ref.read(openSourcesProvider).put(files);
      if (known != source || source.capabilities != files.capabilities) {
        await repositories.sources.save(
          _withCapabilities(source, files.capabilities),
        );
      }

      final folderNames = settings.layoutFolderNames;
      if (folderNames == null) {
        state = const FolderNamesNeeded();
        return;
      }
      ref.read(layoutFolderNamesProvider.notifier).fix(folderNames);

      if (!_initialized) {
        _initialized = true;
        ref.read(foregroundBindingProvider).attach();
        await ref.read(workflowProvider).initialize();
      }
      state = AppReady(files.capabilities);
    } on Object catch (e) {
      // Anything unexpected must show up as a failed start, not a frozen
      // splash screen.
      state = StartupFailed('$e');
    }
  }

  static Source _withLocation(Source source, String location) => Source(
    id: source.id,
    kind: source.kind,
    displayName: source.displayName,
    location: location,
    capabilities: source.capabilities,
    enabled: source.enabled,
  );

  static Source _withCapabilities(
    Source source,
    SourceCapabilities capabilities,
  ) => Source(
    id: source.id,
    kind: source.kind,
    displayName: source.displayName,
    location: source.location,
    capabilities: capabilities,
    enabled: source.enabled,
  );
}

/// The start of the app; `start()` is called by the first screen.
final appControllerProvider = NotifierProvider<AppController, AppStatus>(
  AppController.new,
);
