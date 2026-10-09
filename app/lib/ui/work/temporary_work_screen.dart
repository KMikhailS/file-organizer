import 'dart:async';

import 'package:file_organizer/state/cleanup_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TEMPORARY (decision of task 12, `docs/stage2_android.md`, 5.17): what
/// the workflow does after "Tidy up", with "Cancel" and "Dismiss"; there is
/// no "Apply". The progress and plan screens of task 13 and the result and
/// interrupted-cleanup screens of task 14 replace it. Not localized.
class TemporaryWorkScreen extends ConsumerWidget {
  const TemporaryWorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cleanupStatusProvider);
    final actions = ref.read(cleanupActionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cleanup (preview)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
