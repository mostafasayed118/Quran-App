import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;
  late AyahRepository ayahs;
  late CityRepository city;

  setUp(() async {
    db = newTestDb();
    lastRead = LastReadRepository(db);
    ayahs = AyahRepository(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'Medinan',
          ayahCount: 286,
          pagesStart: 2,
          pagesEnd: 49,
        ));
    await city.select(cairoCity);
    await lastRead.saveAyahId(8);
  });

  for (final inset in <double>[48, 24]) {
    testWidgets('home list padding includes the ${inset.toInt()} dp inset',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(bottom: inset);
      tester.view.viewPadding = FakeViewPadding(bottom: inset);
      addTearDown(tester.view.reset);

      final cubit = HomeCubit(
        lastRead: lastRead,
        ayahs: ayahs,
        prayer: FakePrayerTimeService(),
        city: city,
      );
      addTearDown(cubit.close);
      await cubit.start();
      await pumpAppHost(
        tester,
        wrap: (app) => BlocProvider<HomeCubit>.value(value: cubit, child: app),
        home: const HomeScreen(),
      );

      final list = tester.widget<ListView>(find.byType(ListView));
      final padding = list.padding! as EdgeInsets;
      expect(padding.bottom, 12 + inset);
    });
  }
}
