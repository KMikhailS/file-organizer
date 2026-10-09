import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/ui/texts/date_text.dart';
import 'package:file_organizer/ui/texts/size_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));

  group('sizeText', () {
    test('decimal units, one decimal below 10', () {
      const cases = {
        0: ('0 B', '0 Б'),
        999: ('999 B', '999 Б'),
        1000: ('1 KB', '1 КБ'),
        1500: ('1.5 KB', '1,5 КБ'),
        9949: ('9.9 KB', '9,9 КБ'),
        12345: ('12 KB', '12 КБ'),
        999499: ('999 KB', '999 КБ'),
        // Rounds to 1000 KB: shown in the next unit.
        999960: ('1 MB', '1 МБ'),
        123456789: ('123 MB', '123 МБ'),
        1500000000: ('1.5 GB', '1,5 ГБ'),
        2000000000000: ('2 TB', '2 ТБ'),
      };
      for (final MapEntry(key: bytes, value: (english, russian))
          in cases.entries) {
        expect(sizeText(en, bytes), english, reason: '$bytes');
        expect(sizeText(ru, bytes), russian, reason: '$bytes');
      }
    });

    test('terabytes are the largest unit; thousands are grouped', () {
      expect(sizeText(en, 5000000000000000), '5,000 TB');
      expect(sizeText(ru, 5000000000000000), '5 000 ТБ');
    });

    test('a negative size is a mistake', () {
      expect(() => sizeText(en, -1), throwsArgumentError);
    });
  });

  group('dateText', () {
    setUpAll(() async {
      await initializeDateFormatting('en');
      await initializeDateFormatting('ru');
    });

    test('a local date and time in the language', () {
      final moment = DateTime(2026, 10, 9, 14, 5);
      expect(dateText(en, moment), 'Oct 9, 2026 14:05');
      // A narrow no-break space before «г.».
      expect(dateText(ru, moment), '9 окт. 2026\u202fг. 14:05');
    });

    test('a moment stored in UTC is shown in local time', () {
      final utc = DateTime.utc(2026, 1, 1, 0, 30);
      expect(
        dateText(en, utc),
        DateFormat.yMMMd('en').add_Hm().format(utc.toLocal()),
      );
    });
  });
}
