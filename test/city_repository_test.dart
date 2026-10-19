import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';

import 'support/test_db.dart';

List<Map<String, dynamic>> fixtureRows() => [
      {
        'id': 'c1',
        'nameAr': 'القاهرة',
        'nameEn': 'Cairo',
        'lat': 30.0444,
        'lng': 31.2357
      },
      {
        'id': 'c2',
        'nameAr': 'الرياض',
        'nameEn': 'Riyadh',
        'lat': 24.7136,
        'lng': 46.6753
      },
      {
        'id': 'c3',
        'nameAr': 'دبي',
        'nameEn': 'Dubai',
        'lat': 25.2048,
        'lng': 55.2708
      },
      {
        'id': 'c4',
        'nameAr': 'عمّان',
        'nameEn': 'Amman',
        'lat': 31.9539,
        'lng': 35.9106
      },
      {
        'id': 'c5',
        'nameAr': 'الدار البيضاء',
        'nameEn': 'Casablanca',
        'lat': 33.5731,
        'lng': -7.5898
      },
    ];

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => fixtureRows());
  });

  test('search matches both locales, case-insensitive, trimmed', () async {
    expect((await repo.search('cairo')).single.nameEn, 'Cairo');
    expect((await repo.search('CAIRO')).single.nameEn, 'Cairo');
    expect((await repo.search('الرياض')).single.id, 'c2');
    expect((await repo.search('  riy  ')).single.id, 'c2');
    expect(await repo.search('   '), hasLength(5));
  });

  test('the bundled loader is invoked once across repeated searches', () async {
    var loads = 0;
    final counting = CityRepository(
      db: db,
      loader: () async {
        loads += 1;
        return fixtureRows();
      },
    );
    await counting.search('c');
    await counting.search('ca');
    await counting.search('');
    expect(loads, 1);
  });

  test('concurrent first searches share one loader run', () async {
    var loads = 0;
    final concurrent = CityRepository(
      db: db,
      loader: () async {
        loads += 1;
        await Future<void>.delayed(Duration.zero);
        return fixtureRows();
      },
    );

    await Future.wait([concurrent.search('c'), concurrent.search('r')]);

    expect(loads, 1);
  });

  test('select persists and round-trips via the settings table', () async {
    const cairo = City(
        id: 'c1',
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        lat: 30.0444,
        lng: 31.2357);
    await repo.select(cairo);

    final restored = await repo.selectedCity();
    expect(restored, isNotNull);
    expect(restored!.id, 'c1');
    expect(restored.lat, 30.0444);
    expect(restored.coordinates.latitude, 30.0444);

    final raw = await repo.selectedCityJson();
    expect(raw, isNotNull);
    expect((jsonDecode(raw!) as Map<String, dynamic>)['nameAr'], 'القاهرة');
  });

  test('empty/missing selection returns null', () async {
    expect(await repo.selectedCity(), isNull);
    expect(await repo.selectedCityJson(), isNull);
  });

  test('bundled cities asset is well-formed (>=150 complete entries)', () {
    final file = File('assets/data/cities.json');
    if (!file.existsSync()) {
      markTestSkipped(
          'working dir does not resolve the bundled asset from this runner');
    }
    final list = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    expect(list.length, greaterThanOrEqualTo(150));
    for (final row in list) {
      expect(row.containsKey('id'), isTrue, reason: 'row missing id: $row');
      expect(row.containsKey('nameAr'), isTrue);
      expect(row.containsKey('nameEn'), isTrue);
      final lat = (row['lat'] as num).toDouble();
      final lng = (row['lng'] as num).toDouble();
      expect(lat, inInclusiveRange(-90, 90), reason: 'row lat: $row');
      expect(lng, inInclusiveRange(-180, 180), reason: 'row lng: $row');
    }
  });
}
