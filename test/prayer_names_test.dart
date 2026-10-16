import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/l10n/prayer_names.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  testWidgets('PrayerNameLabel maps every prayer to its existing l10n key',
      (tester) async {
    late AppLocalizations loc;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          loc = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ));

    expect(PrayerName.fajr.label(loc), 'فجر');
    expect(PrayerName.sunrise.label(loc), 'شروق');
    expect(PrayerName.dhuhr.label(loc), 'الظهر');
    expect(PrayerName.asr.label(loc), 'العصر');
    expect(PrayerName.maghrib.label(loc), 'المغرب');
    expect(PrayerName.isha.label(loc), 'العشاء');
  });
}
