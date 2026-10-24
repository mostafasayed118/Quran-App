import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_state.dart';

import 'prayer_times_cubit_test.dart' show cairoCity, dubaiCity;
import 'support/test_db.dart';

class _FlakySelectRepo extends CityRepository {
  _FlakySelectRepo(AppDatabase db)
      : super(
          db: db,
          loader: () async => [cairoCity.toJson(), dubaiCity.toJson()],
        );

  bool failSelect = false;

  @override
  Future<void> select(City city) async {
    if (failSelect) throw StateError('boom');
    await super.select(city);
  }
}

void main() {
  late AppDatabase db;
  late _FlakySelectRepo repo;

  setUp(() {
    db = newTestDb();
    repo = _FlakySelectRepo(db);
  });

  test('a throwing select returns false and keeps the selection', () async {
    final cubit = CityPickerCubit(cityRepo: repo);
    await cubit.search('');
    expect((cubit.state as CityPickerReady).selectedCityId, isNull);

    repo.failSelect = true;
    final persisted = await cubit.persist(cairoCity);
    await cubit.search('');

    expect(persisted, isFalse);
    expect((cubit.state as CityPickerReady).selectedCityId, isNull);
    expect(await repo.selectedCity(), isNull);

    await cubit.close();
  });

  test('a successful select returns true and marks the selection', () async {
    final cubit = CityPickerCubit(cityRepo: repo);
    await cubit.search('');

    final persisted = await cubit.persist(dubaiCity);
    await cubit.search('');

    expect(persisted, isTrue);
    expect((cubit.state as CityPickerReady).selectedCityId, 'dubai');
    expect((await repo.selectedCity())!.id, 'dubai');

    await cubit.close();
  });
}
