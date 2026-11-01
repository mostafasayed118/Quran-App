import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_screen.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/host.dart';
import 'support/test_db.dart';

/// After Isha the panel used to go silent while Home advertised tomorrow's
/// Fajr. These tests pin the footer that closes that gap.
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
      ];
  });

  Future<void> pumpAt(WidgetTester tester, DateTime now) async {
    final cubit = PrayerTimesCubit(
      prayer: fake,
      city: repo,
      clock: () => now,
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

  testWidgets('after Isha the panel names tomorrow\'s Fajr and counts down',
      (tester) async {
    await repo.select(cairoCity);
    fake.nextResult =
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));

    await pumpAt(tester, DateTime(2026, 3, 15, 20, 0));

    expect(find.text('غدًا فجر ٠٤:٤٥'), findsOneWidget);
    expect(find.text('متبقٍ ٠٨:٤٥'), findsOneWidget);
    expect(find.byIcon(Icons.nights_stay_outlined), findsOneWidget);
    // The panel still lists today's six times exactly once each.
    expect(find.text('فجر'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);
  });

  testWidgets('while a prayer is still ahead no tomorrow note is rendered',
      (tester) async {
    await repo.select(cairoCity);
    fake.nextResult =
        PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));

    await pumpAt(tester, DateTime(2026, 3, 15, 14, 0));

    expect(find.textContaining('غدًا'), findsNothing);
    expect(find.byIcon(Icons.nights_stay_outlined), findsNothing);
  });
}
