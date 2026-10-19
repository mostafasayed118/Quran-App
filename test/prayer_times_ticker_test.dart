import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_screen.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_state.dart';
import 'prayer_times_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/host.dart';

List<PrayerChoice> dayOn(int y, int m, int d) => [
      PrayerChoice(PrayerName.fajr, DateTime(y, m, d, 4, 45)),
      PrayerChoice(PrayerName.sunrise, DateTime(y, m, d, 6, 10)),
      PrayerChoice(PrayerName.dhuhr, DateTime(y, m, d, 12, 5)),
      PrayerChoice(PrayerName.asr, DateTime(y, m, d, 15, 35)),
      PrayerChoice(PrayerName.maghrib, DateTime(y, m, d, 18, 5)),
      PrayerChoice(PrayerName.isha, DateTime(y, m, d, 19, 30)),
    ];

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await repo.select(cairoCity);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester, PrayerTimesCubit cubit) async {
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) =>
          BlocProvider<PrayerTimesCubit>.value(value: cubit, child: app),
      home: const PrayerTimesScreen(),
    );
  }

  test('after Isha the already-passed Fajr row is not flagged as next',
      () async {
    final fake = FakePrayerTimeService()
      ..todayResult = dayOn(2026, 3, 15)
      ..nextResult =
          PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));
    final cubit = PrayerTimesCubit(
      prayer: fake,
      city: repo,
      clock: () => DateTime(2026, 3, 15, 23, 50),
    );

    await cubit.reload();

    final ready = cubit.state as PrayerTimesReady;
    expect(ready.entries, hasLength(6));
    expect(ready.entries.where((e) => e.isNext), isEmpty);
    expect(ready.remaining, isNull);

    await cubit.close();
  });

  testWidgets(
      'the countdown refreshes as minutes pass while the screen sits open',
      (tester) async {
    var now = DateTime(2026, 3, 15, 14, 0);
    final fake = FakePrayerTimeService()
      ..todayResult = dayOn(2026, 3, 15)
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
    final cubit = PrayerTimesCubit(prayer: fake, city: repo, clock: () => now);

    await pumpScreen(tester, cubit);
    expect(find.text('متبقٍ ٠١:٣٥'), findsOneWidget);

    now = DateTime(2026, 3, 15, 14, 1);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('متبقٍ ٠١:٣٤'), findsOneWidget);
    expect(find.text('متبقٍ ٠١:٣٥'), findsNothing);
  });

  testWidgets('when the flagged prayer passes, the highlight advances',
      (tester) async {
    var now = DateTime(2026, 3, 15, 15, 34);
    final fake = FakePrayerTimeService()
      ..todayResult = dayOn(2026, 3, 15)
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
    final cubit = PrayerTimesCubit(prayer: fake, city: repo, clock: () => now);

    await pumpScreen(tester, cubit);
    expect(find.text('متبقٍ ٠٠:٠١'), findsOneWidget);

    now = DateTime(2026, 3, 15, 15, 36);
    fake.nextResult =
        PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('متبقٍ ٠٢:٢٩'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });
}
