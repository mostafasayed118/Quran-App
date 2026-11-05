import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/forbidden_windows_section.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_state.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

List<PrayerEntry> _entries() => [
      PrayerEntry(
        name: PrayerName.fajr,
        time: DateTime(2026, 11, 5, 4, 45),
        isNext: false,
      ),
      PrayerEntry(
        name: PrayerName.sunrise,
        time: DateTime(2026, 11, 5, 6, 10),
        isNext: false,
      ),
      PrayerEntry(
        name: PrayerName.dhuhr,
        time: DateTime(2026, 11, 5, 11, 40),
        isNext: false,
      ),
      PrayerEntry(
        name: PrayerName.asr,
        time: DateTime(2026, 11, 5, 14, 42),
        isNext: false,
      ),
      PrayerEntry(
        name: PrayerName.maghrib,
        time: DateTime(2026, 11, 5, 17, 4),
        isNext: false,
      ),
      PrayerEntry(
        name: PrayerName.isha,
        time: DateTime(2026, 11, 5, 18, 24),
        isNext: false,
      ),
    ];

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: app!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders the three windows and their ranges', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(
      ForbiddenWindowsSection(entries: _entries()),
    ));
    await tester.pump();

    expect(find.text('أوقات النهي'), findsOneWidget);
    expect(find.text('بعد الفجر حتى الشروق'), findsOneWidget);
    expect(find.text('قبيل الظهر'), findsOneWidget);
    expect(find.text('بعد العصر حتى المغرب'), findsOneWidget);
    expect(find.textContaining('٤:٤٥'), findsOneWidget);
    expect(find.textContaining('٦:١٠'), findsOneWidget);
    expect(find.textContaining('١١:٣٠'), findsOneWidget);
    expect(find.textContaining('١٤:٤٢'), findsOneWidget);
    expect(find.textContaining('١٧:٠٤'), findsOneWidget);
  });

  testWidgets('survives textScale 2.0 at 360 wide', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(
      ForbiddenWindowsSection(entries: _entries()),
      textScale: 2,
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing sunrise hides the section', (tester) async {
    final entries =
        _entries().where((entry) => entry.name != PrayerName.sunrise).toList();

    await tester.pumpWidget(_app(ForbiddenWindowsSection(entries: entries)));
    await tester.pump();

    expect(find.text('أوقات النهي'), findsNothing);
  });
}
