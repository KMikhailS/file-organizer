import 'dart:async';

import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/app_status.dart';
import 'package:file_organizer/state/notification_permission.dart';
import 'package:file_organizer/ui/onboarding/folder_names_step.dart';
import 'package:file_organizer/ui/onboarding/onboarding_page.dart';
import 'package:file_organizer/ui/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first start (`docs/stage2_android.md`, section 9 and 5.17): what the
/// app does and why it is safe → "All files access" → notifications
/// (Android 13+) → the folder names. Steps already done are skipped, so
/// after a restart it goes on from the first one still open.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _introDone = false;
  bool _accessAsked = false;
  bool _notificationsAsked = false;
  bool _notificationsSkipped = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appControllerProvider);
    final notifications = ref.watch(notificationPermissionProvider);
    if (!_introDone) {
      return _Intro(onNext: () => setState(() => _introDone = true));
    }
    if (status is AccessNeeded) {
      return _Access(notGranted: _accessAsked, onGrant: _requestAccess);
    }
    final notificationsAllowed = switch (notifications) {
      AsyncData(:final value) => value,
      AsyncError() => false,
      _ => null,
    };
    if (notificationsAllowed == null) {
      return const SplashScreen();
    }
    if (!notificationsAllowed && !_notificationsSkipped) {
      return _Notifications(
        denied: _notificationsAsked,
        onAllow: _requestNotifications,
        onSkip: () => setState(() => _notificationsSkipped = true),
      );
    }
    if (status case FolderNamesNeeded(:final saving)) {
      return FolderNamesStep(saving: saving);
    }
    // The start goes on (opening the storage); the home screen follows.
    return const SplashScreen();
  }

  Future<void> _requestAccess() async {
    await ref.read(appControllerProvider.notifier).requestAccess();
    if (mounted) {
      setState(() => _accessAsked = true);
    }
  }

  Future<void> _requestNotifications() async {
    await ref.read(notificationPermissionProvider.notifier).request();
    if (mounted) {
      setState(() => _notificationsAsked = true);
    }
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OnboardingPage(
      icon: Icons.auto_awesome_outlined,
      title: l.introTitle,
      actions: [FilledButton(onPressed: onNext, child: Text(l.onboardingNext))],
      children: [
        Text(l.introText),
        const SizedBox(height: 16),
        for (final (icon, title, text) in [
          (Icons.checklist, l.introPlanTitle, l.introPlanText),
          (
            Icons.inventory_2_outlined,
            l.introQuarantineTitle,
            l.introQuarantineText,
          ),
          (Icons.undo, l.introUndoTitle, l.introUndoText),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(text),
          ),
      ],
    );
  }
}

class _Access extends StatelessWidget {
  const _Access({required this.notGranted, required this.onGrant});

  /// The user came back from the system settings without the access.
  final bool notGranted;
  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OnboardingPage(
      icon: Icons.folder_open_outlined,
      title: l.accessTitle,
      actions: [
        FilledButton(
          onPressed: () => unawaited(onGrant()),
          child: Text(l.grantAccess),
        ),
      ],
      children: [
        Text(l.accessText),
        if (notGranted) ...[
          const SizedBox(height: 16),
          Text(
            l.accessNotGranted,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications({
    required this.denied,
    required this.onAllow,
    required this.onSkip,
  });

  /// The user was asked and did not allow them.
  final bool denied;
  final Future<void> Function() onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OnboardingPage(
      icon: Icons.notifications_outlined,
      title: l.notificationsTitle,
      actions: [
        FilledButton(
          onPressed: () => unawaited(onAllow()),
          child: Text(l.allowNotifications),
        ),
        if (denied)
          OutlinedButton(
            onPressed: onSkip,
            child: Text(l.continueWithoutNotifications),
          ),
      ],
      children: [
        Text(l.notificationsText),
        if (denied) ...[
          const SizedBox(height: 16),
          Text(l.notificationsDenied),
        ],
      ],
    );
  }
}
