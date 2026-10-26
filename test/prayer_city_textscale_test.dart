import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_screen.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  Future<void> pumpScaled(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2.0)),
        child: child!,
      ),
      home: home,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('prayer times list + countdown survive textScale 2.0',
      (tester) async {
    await repo.select(cairoCity);
    final fake = FakePrayerTimeService()
      ..todayResult = [
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
        PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
        PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
        PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
        PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
        PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
      ]
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
    final cubit = PrayerTimesCubit(
      prayer: fake,
      city: repo,
      clock: () => DateTime(2026, 3, 15, 14, 0),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await pumpScaled(
      tester,
      BlocProvider<PrayerTimesCubit>.value(
        value: cubit,
        child: const PrayerTimesScreen(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('متبقٍ ٠١:٣٥'), findsOneWidget);
  });

  testWidgets('city picker rows + selected mark survive textScale 2.0',
      (tester) async {
    await repo.select(cairoCity);
    final cubit = CityPickerCubit(cityRepo: repo);
    addTearDown(cubit.close);
    await cubit.start();

    await pumpScaled(
      tester,
      BlocProvider<CityPickerCubit>.value(
        value: cubit,
        child: const CityPickerScreen(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
