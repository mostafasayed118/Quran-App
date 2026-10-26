import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_state.dart';

const _cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

const _alexandria = City(
  id: 'alexandria',
  nameAr: 'الإسكندرية',
  nameEn: 'Alexandria',
  lat: 31.2001,
  lng: 29.9187,
);

class GatedCityRepository implements CityRepository {
  final Completer<void> slowSearch = Completer<void>();

  @override
  Future<List<City>> search(String query) async {
    if (query == 'slow') {
      await slowSearch.future;
      return const [_cairo];
    }
    if (query == 'fresh') return const [_alexandria];
    return const <City>[];
  }

  @override
  Future<City?> selectedCity() async => null;

  @override
  Future<String?> selectedCityJson() async => null;

  @override
  Future<void> select(City city) async {}

  @override
  Future<City> nearestTo(double lat, double lng) async => _cairo;
}

void main() {
  test('a slow older search cannot overwrite the newer results', () async {
    final repo = GatedCityRepository();
    final cubit = CityPickerCubit(cityRepo: repo);
    await cubit.start();

    expect(cubit.state, isA<CityPickerReady>());

    final slow = cubit.search('slow');
    await Future<void>.delayed(Duration.zero);
    final fresh = cubit.search('fresh');
    await fresh;

    var ready = cubit.state as CityPickerReady;
    expect(ready.query, 'fresh');
    expect(ready.results.single.id, 'alexandria');

    repo.slowSearch.complete();
    await slow;

    ready = cubit.state as CityPickerReady;
    expect(ready.query, 'fresh');
    expect(ready.results.single.id, 'alexandria');

    await cubit.close();
  });
}
