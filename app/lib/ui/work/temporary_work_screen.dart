import 'dart:async';

import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TEMPORARY (`docs/stage2_android.md`, 5.19): the interrupted cleanup
/// found at start-up, with "Make a plan" (finish the job) and "Dismiss".
/// The screen of task 14 ("finish" or "undo") replaces it. Not localized.
class TemporaryWorkScreen extends ConsumerWidget {
  const TemporaryWorkScreen({required this.interrupted, super.key});

  final InterruptedCleanup interrupted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(cleanupActionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Interrupted cleanup (preview)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interrupted cleanup: ${interrupted.recovered} recovered, '
              '${interrupted.unavailable} unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: () => unawaited(actions.plan()),
                  child: const Text('Make a plan'),
                ),
                OutlinedButton(
                  onPressed: actions.dismiss,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
