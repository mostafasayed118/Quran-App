import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_times/prayer_times_state.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService;
import 'support/test_db.dart';

class ThrowingCityRepository extends CityRepository {
  ThrowingCityRepository({required super.db, required super.loader});

  @override
  Future<City?> selectedCity() async {
    throw StateError('city read failed');
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  test('a throwing city read emits loading then failed, never hangs', () async {
    final cubit = PrayerTimesCubit(
      prayer: FakePrayerTimeService(),
      city: ThrowingCityRepository(
        db: db,
        loader: () async => const <Map<String, dynamic>>[],
      ),
    );

    expect(cubit.state, isA<PrayerTimesLoading>());

    await cubit.reload();

    expect(cubit.state, isA<PrayerTimesFailed>());
    expect(cubit.state, isNot(isA<PrayerTimesLoading>()));

    await cubit.close();
  });
}
