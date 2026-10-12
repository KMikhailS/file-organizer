import 'dart:async';

import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/state/notification_permission.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/ui/cleanup/plan_failed_screen.dart';
import 'package:file_organizer/ui/cleanup/plan_screen.dart';
import 'package:file_organizer/ui/cleanup/progress_screen.dart';
import 'package:file_organizer/ui/home/home_screen.dart';
import 'package:file_organizer/ui/onboarding/onboarding_screen.dart';
import 'package:file_organizer/ui/splash_screen.dart';
import 'package:file_organizer/ui/startup_failed_screen.dart';
import 'package:file_organizer/ui/work/temporary_work_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Picks the screen (`docs/stage2_android.md`, 5.17): the splash while the
/// app starts, the onboarding until the folder names are fixed (the first
/// start), then the home screen; the error screen when the start fails.
///
/// Starts the app, and starts it again on returning to it: the access may
/// have been granted or taken back in the system settings meanwhile.
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen>
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appControllerProvider.notifier).start());
      unawaited(ref.read(notificationPermissionProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appControllerProvider);
    final folderNames = ref.watch(layoutFolderNamesProvider);
    return switch (status) {
      AppStarting() => const SplashScreen(),
      StartupFailed(:final reason) => StartupFailedScreen(reason: reason),
      _ when folderNames == null => const OnboardingScreen(),
      _ => const _HomeOrWork(),
    };
  }
}

/// The home screen, or the cleanup screen of what the workflow does: its
/// progress, the plan, a failure; an interrupted cleanup on the temporary
/// screen until task 14.
class _HomeOrWork extends ConsumerWidget {
  const _HomeOrWork();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(cleanupViewProvider)) {
        AtHome() => const HomeScreen(),
        final InProgress progress => ProgressScreen(progress: progress),
        final PlanReview review => PlanScreen(review: review),
        PlanFailed(:final reason) => PlanFailedScreen(reason: reason),
        final InterruptedCleanup interrupted => TemporaryWorkScreen(
          interrupted: interrupted,
        ),
      };
}
