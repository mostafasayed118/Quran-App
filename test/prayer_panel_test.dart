import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_screen.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService;
import 'support/host.dart';
import 'support/test_db.dart';

class _ThrowingPrayerService implements PrayerTimeService {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      throw StateError('prayer service down');

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      throw StateError('prayer service down');
}

void main() {
  late AppDatabase db;
  late CityRepository repo;
  late FakePrayerTimeService fake;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    fake = FakePrayerTimeService()
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
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    PrayerTimeService? service,
  }) async {
    final cubit = PrayerTimesCubit(
      prayer: service ?? fake,
      city: repo,
      clock: () => DateTime(2026, 3, 15, 14, 0),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) =>
          BlocProvider<PrayerTimesCubit>.value(value: cubit, child: app),
      home: const PrayerTimesScreen(),
    );
  }

  testWidgets('the six times live in one panel instead of six cards',
      (tester) async {
    await repo.select(cairoCity);
    await pumpScreen(tester);

    // City header + the single times panel.
    expect(find.byType(Card), findsNWidgets(2));
  });

  testWidgets('only the next prayer carries the schedule glyph',
      (tester) async {
    await repo.select(cairoCity);
    await pumpScreen(tester);

    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('sunrise is marked as a time marker, not as a prayer',
      (tester) async {
    await repo.select(cairoCity);
    await pumpScreen(tester);

    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('a failed load offers a retry action', (tester) async {
    await repo.select(cairoCity);
    await pumpScreen(tester, service: _ThrowingPrayerService());

    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
    expect(find.text('أعِد المحاولة'), findsOneWidget);
  });
}
