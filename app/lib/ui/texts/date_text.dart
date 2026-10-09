import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// A moment (stored in UTC) as a local date and time in the user's
/// language: `Oct 9, 2026 14:05`, `9 окт. 2026 г. 14:05`.
///
/// The date symbols come with the Material localizations, which
/// `AppLocalizations.localizationsDelegates` load.
String dateText(AppLocalizations l, DateTime moment) =>
    DateFormat.yMMMd(l.localeName).add_Hm().format(moment.toLocal());
