import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/di/injector.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';

import 'support/fakes.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
    resetDependenciesForTest();
  });

  test('the reset hook lets a second configure build a fresh graph', () async {
    await configureDependencies();
    final first = getIt<CityRepository>();

    await getIt.reset();
    // Without the hook this second configure would return immediately and
    // `first` would still be the registered instance.
    resetDependenciesForTest();
    await configureDependencies(
      citiesLoader: () async => [cairoCity.toJson()],
    );

    final second = getIt<CityRepository>();
    expect(identical(first, second), isFalse);
    expect(await second.search(''), hasLength(1));
  });
}
