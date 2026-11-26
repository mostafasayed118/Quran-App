import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_state.dart';

import 'support/fakes.dart';
import 'support/prayer_fixtures.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late CityRepository repo;
  late FakePrayerTimeService fake;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(
      db: db,
      loader: () async => [cairoCity.toJson(), dubaiCity.toJson()],
    );
    fake = FakePrayerTimeService()
      ..todayResult = fakeDay()
      ..nextResult = PrayerChoice(
        PrayerName.asr,
        DateTime(2026, 3, 15, 15, 35),
      );
  });

  test('no selection emits ready with no city and empty entries', () async {
    final cubit = PrayerTimesCubit(prayer: fake, city: repo);
    await cubit.reload();

    final state = cubit.state;
    expect(state, isA<PrayerTimesReady>());
    final ready = state as PrayerTimesReady;
    expect(ready.city, isNull);
    expect(ready.entries, isEmpty);

    await cubit.close();
  });

  test(
    'with selection: entries ordered with times and the next anchor flagged',
    () async {
      await repo.select(cairoCity);
      final cubit = PrayerTimesCubit(prayer: fake, city: repo);
      await cubit.reload();

      final ready = cubit.state as PrayerTimesReady;
      expect(ready.city!.id, 'cairo');
      expect(ready.entries.map((e) => e.name), PrayerName.values);
      final nextList = ready.entries.where((e) => e.isNext).toList();
      expect(nextList, hasLength(1));
      expect(nextList.single.name, PrayerName.asr);
      expect(nextList.single.time, DateTime(2026, 3, 15, 15, 35));

      await cubit.close();
    },
  );
}
