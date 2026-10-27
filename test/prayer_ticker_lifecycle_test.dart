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
import 'prayer_times_ticker_test.dart' show dayOn;
import 'support/host.dart';
import 'support/test_db.dart';

const _remainingOneThirtyFive = Duration(hours: 1, minutes: 35);

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await repo.select(cairoCity);
  });

  Future<PrayerTimesCubit> pumpScreen(
    WidgetTester tester,
    DateTime Function() clock,
  ) async {
    final fake = FakePrayerTimeService()
      ..todayResult = dayOn(2026, 3, 15)
      ..nextResult =
          PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
    final cubit = PrayerTimesCubit(prayer: fake, city: repo, clock: clock);
    await cubit.start();
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) =>
          BlocProvider<PrayerTimesCubit>.value(value: cubit, child: app),
      home: const PrayerTimesScreen(),
    );
    expect(find.text('متبقٍ ٠١:٣٥'), findsOneWidget);
    return cubit;
  }

  Duration? remainingOf(PrayerTimesCubit cubit) =>
      (cubit.state as PrayerTimesReady).remaining;

  testWidgets('paused stops the ticker and resumed restarts it',
      (tester) async {
    var now = DateTime(2026, 3, 15, 14, 0);
    final cubit = await pumpScreen(tester, () => now);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(
      () => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    now = DateTime(2026, 3, 15, 14, 1);
    await tester.pump(const Duration(seconds: 1));

    // Paused frames are not drawn, so the cubit state is the real proof that
    // the periodic wakeup no longer ran.
    expect(remainingOf(cubit), _remainingOneThirtyFive);
    expect(find.text('متبقٍ ٠١:٣٥'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('متبقٍ ٠١:٣٤'), findsOneWidget);
  });

  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
  ]) {
    testWidgets('$state stops the ticker', (tester) async {
      var now = DateTime(2026, 3, 15, 14, 0);
      final cubit = await pumpScreen(tester, () => now);

      tester.binding.handleAppLifecycleStateChanged(state);
      addTearDown(
        () => tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      now = DateTime(2026, 3, 15, 14, 1);
      await tester.pump(const Duration(seconds: 1));

      expect(remainingOf(cubit), _remainingOneThirtyFive);
      expect(find.text('متبقٍ ٠١:٣٥'), findsOneWidget);
    });
  }
}
