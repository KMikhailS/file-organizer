import 'package:file_organizer/core/model/session_status.dart';
import 'package:file_organizer/l10n/app_localizations.dart';

/// The status of a cleanup in the user's language.
String sessionStatusText(AppLocalizations l, SessionStatus status) =>
    switch (status) {
      SessionStatus.completed => l.sessionCompleted,
      SessionStatus.failed => l.sessionFailed,
      SessionStatus.cancelled => l.sessionCancelled,
      SessionStatus.reverted => l.sessionReverted,
      SessionStatus.partiallyReverted => l.sessionPartiallyReverted,
      // Still running in the journal: its storage was not there for
      // recovery.
      SessionStatus.running => l.sessionInterrupted,
      // Never shown: planned sessions are not in the history.
      SessionStatus.planned => '',
    };
