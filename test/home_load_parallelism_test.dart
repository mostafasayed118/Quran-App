import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_state.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_source.dart';
import 'package:quran_yahdi/features/quran/data/last_read_source.dart';

import 'support/test_db.dart';

const cairoCity = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

/// Blocks the last-read chain until the test releases it, so the next-prayer
/// chain's start time is observable.
class _GatedLastRead implements LastReadSource {
  final gate = Completer<int?>();

  @override
  Future<int?> loadAyahId() => gate.future;

  @override
  Future<void> saveAyahId(int ayahId) async {}
}

class _ThrowingLastRead implements LastReadSource {
  @override
  Future<int?> loadAyahId() async => throw StateError('last read down');

  @override
  Future<void> saveAyahId(int ayahId) async {}
}

class _CountingCity extends CityRepository {
  _CountingCity({required super.db, required super.loader});

  int selectedCityCalls = 0;

  @override
  Future<City?> selectedCity() {
    selectedCityCalls++;
    return super.selectedCity();
  }
}

class _ThrowingCity extends CityRepository {
  _ThrowingCity({required super.db, required super.loader});

  @override
  Future<City?> selectedCity() async => throw StateError('city down');
}

class _UnusedAyahs implements AyahSource {
  @override
  Future<Ayah?> ayahById(int ayahId) => throw UnimplementedError();

  @override
  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah) =>
      throw UnimplementedError();

  @override
  Future<Surah?> surahById(int surahId) => throw UnimplementedError();

  @override
  Future<List<Ayah>> surahAyahs(int surahId) => throw UnimplementedError();

  @override
  Future<void> toggleBookmark(int ayahId) => throw UnimplementedError();

  @override
  Future<void> deleteBookmark(int ayahId) async {}

  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() =>
      throw UnimplementedError();

  @override
  Stream<Set<int>> watchBookmarkedIds() => throw UnimplementedError();
}

class _FakePrayerTimeService implements PrayerTimeService {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      throw UnimplementedError();

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));
}

Future<void> _pumpUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition was not reached within 5s');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late AppDatabase db;
  late _CountingCity city;

  setUp(() async {
    db = newTestDb();
    city = _CountingCity(db: db, loader: () async => [cairoCity.toJson()]);
    await city.select(cairoCity);
  });

  test('the next-prayer chain starts while the last-read chain is gated',
      () async {
    final lastRead = _GatedLastRead();
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: _UnusedAyahs(),
      prayer: _FakePrayerTimeService(),
      city: city,
    );
    addTearDown(cubit.close);

    final reload = cubit.reload();

    await _pumpUntil(() => city.selectedCityCalls > 0);
    expect(lastRead.gate.isCompleted, isFalse,
        reason: 'the gate must still be pending for the proof to hold');
    expect(city.selectedCityCalls, greaterThan(0),
        reason:
            'the independent next-prayer chain must not wait for last-read');

    lastRead.gate.complete(null);
    await reload;

    final ready = cubit.state as HomeReady;
    expect(ready.lastRead, isNull);
    expect(ready.nextPrayer, isNotNull);
    expect(ready.nextPrayer!.name, PrayerName.fajr);
  });

  test('both chains throwing emits exactly one failed state', () async {
    final cubit = HomeCubit(
      lastRead: _ThrowingLastRead(),
      ayahs: _UnusedAyahs(),
      prayer: _FakePrayerTimeService(),
      city: _ThrowingCity(db: db, loader: () async => [cairoCity.toJson()]),
    );
    addTearDown(cubit.close);
    final states = <HomeState>[];
    final sub = cubit.stream.listen(states.add);
    addTearDown(sub.cancel);

    await _pumpUntil(() => states.whereType<HomeFailed>().isNotEmpty);
    await Future<void>.delayed(Duration.zero);

    expect(states.whereType<HomeFailed>(), hasLength(1),
        reason: 'the second error must be consumed, not emitted twice');
    expect(cubit.state, isA<HomeFailed>());
  });
}
