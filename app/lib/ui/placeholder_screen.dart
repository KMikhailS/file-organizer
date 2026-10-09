import 'dart:async';

import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/cleanup_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TEMPORARY screen of stage 2, task 10: the start, the access, and a plan
/// without applying it, to check the wiring and the life cycle on a device.
/// Tasks 12–14 replace it with the real screens.
class PlaceholderScreen extends ConsumerStatefulWidget {
  const PlaceholderScreen({super.key});

  @override
  ConsumerState<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends ConsumerState<PlaceholderScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ref.read(appControllerProvider.notifier).start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Access may have been granted in the system settings meanwhile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appControllerProvider.notifier).start());
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('File Organizer (preview)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (app) {
          AppStarting() => const Center(child: CircularProgressIndicator()),
          AccessNeeded() => _AccessNeeded(
            onGrant: () =>
                ref.read(appControllerProvider.notifier).requestAccess(),
          ),
          StartupFailed(:final reason) => Text('Could not start: $reason'),
          AppReady() => const _Cleanup(),
        },
      ),
    );
  }
}

class _AccessNeeded extends StatelessWidget {
  const _AccessNeeded({required this.onGrant});

  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('The app needs "All files access" to look at your files.'),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => unawaited(onGrant()),
        child: const Text('Grant access'),
      ),
    ],
  );
}

class _Cleanup extends ConsumerWidget {
  const _Cleanup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cleanupStatusProvider);
    final actions = ref.read(cleanupActionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status.text, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: status.canPlan
                  ? () => unawaited(actions.plan())
                  : null,
              child: const Text('Make a plan'),
            ),
            OutlinedButton(
              onPressed: status.canCancel ? actions.cancel : null,
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: status.canDismiss ? actions.dismiss : null,
              child: const Text('Dismiss plan'),
            ),
          ],
        ),
      ],
    );
  }
}
