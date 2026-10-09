import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// A size in the user's language, in decimal units like Android shows
/// them: `999 B`, `1.5 KB`, `12 MB` (`1,5 КБ` in Russian). One decimal
/// below 10, none above.
String sizeText(AppLocalizations l, int bytes) {
  if (bytes < 0) {
    throw ArgumentError.value(bytes, 'bytes', 'a size is not negative');
  }
  final units = <String Function(String)>[
    l.sizeBytes,
    l.sizeKilobytes,
    l.sizeMegabytes,
    l.sizeGigabytes,
    l.sizeTerabytes,
  ];
  var value = bytes.toDouble();
  var unit = 0;
  // Rounded first, so that 999 960 bytes show as 1 MB, not 1000 KB.
  while (unit < units.length - 1 && _rounded(value) >= 1000) {
    value /= 1000;
    unit++;
  }
  final pattern = value < 10 ? '0.#' : '#,##0';
  return units[unit](NumberFormat(pattern, l.localeName).format(value));
}

double _rounded(double value) =>
    value < 10 ? (value * 10).round() / 10 : value.roundToDouble();
