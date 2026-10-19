import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_state.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';

import 'support/test_db.dart';

class FakePrayerTimeService implements PrayerTimeService {
  PrayerChoice? nextResult;
  bool throwOnNext = false;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      throw UnimplementedError();

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    if (throwOnNext) throw StateError('prayer service down');
    return nextResult ??
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));
  }
}

const cairoCity = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;
  late AyahRepository ayahs;
  late CityRepository city;
  late FakePrayerTimeService fake;

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
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(8),
          surahId: 2,
          numberInSurah: 1,
          juz: 1,
          page: 2,
          textUthmani: 'الم',
          textImlaei: 'الم',
        ));
    fake = FakePrayerTimeService();
  });

  Future<HomeCubit> build() async {
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: fake,
      city: city,
    );
    await cubit.reload();
    return cubit;
  }

  test('no last-read and no city emits ready with both cards null', () async {
    final cubit = await build();
    final ready = cubit.state as HomeReady;
    expect(ready.lastRead, isNull);
    expect(ready.nextPrayer, isNull);
    await cubit.close();
  });

  test('seeded last-read populates surahName and ayah', () async {
    await lastRead.saveAyahId(8);
    final cubit = await build();
    final ready = cubit.state as HomeReady;
    expect(ready.lastRead, isNotNull);
    expect(ready.lastRead!.surahId, 2);
    expect(ready.lastRead!.surahName, 'البقرة');
    expect(ready.lastRead!.ayahNumber, 1);
    expect(ready.nextPrayer, isNull);
    await cubit.close();
  });

  test('seeded city populates the next-prayer card from the service', () async {
    await city.select(cairoCity);
    fake.nextResult =
        PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35));
    final cubit = await build();
    final ready = cubit.state as HomeReady;
    expect(ready.nextPrayer, isNotNull);
    expect(ready.nextPrayer!.name, PrayerName.asr);
    expect(ready.nextPrayer!.time, DateTime(2026, 3, 15, 15, 35));
    expect(ready.lastRead, isNull);
    await cubit.close();
  });

  test('a throwing load emits failed instead of hanging on loading', () async {
    await city.select(cairoCity);
    fake.throwOnNext = true;
    final cubit = await build();
    expect(cubit.state, isA<HomeFailed>());
    await cubit.close();
  });
}
