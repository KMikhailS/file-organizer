import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:file_organizer/platform/android/android_native.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/app_texts.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts the app (`docs/stage2_android.md`, section 7): database →
/// "All files access" → the shared storage source (created on the first
/// start) is opened → the workflow recovers interrupted sessions and purges
/// the expired quarantine → the foreground service follows the workflow.
///
/// Without access the workflow is not initialized: recovery needs the
/// source. [requestAccess] or a later [start] picks up from there.
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

  Future<void> _start() async {
    if (state is AppReady) {
      return;
    }
    final services = ref.read(appServicesProvider);
    final native = services.native;
    try {
      final repositories = ref.read(repositoriesProvider);
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
            displayName: AppTexts.internalStorage,
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
