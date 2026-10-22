import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_state.dart';

import 'support/fakes.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  tearDown(() => db.close());

  test('the cubit starts in loading until the first reload completes',
      () async {
    final cubit = QiblaCubit(city: repo, qibla: FakeQiblaService());
    addTearDown(cubit.close);

    expect(cubit.state, isA<QiblaLoading>());
    await cubit.reload();
    expect(cubit.state, isA<QiblaReady>());
  });
}
