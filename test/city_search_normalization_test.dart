import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';

List<Map<String, dynamic>> _rows() => [
      {
        'id': 'alex',
        'nameAr': 'الإسكندرية',
        'nameEn': 'Alexandria',
        'lat': 31.2001,
        'lng': 29.9187,
      },
      {
        'id': 'cairo',
        'nameAr': 'القاهرة',
        'nameEn': 'Cairo',
        'lat': 30.0444,
        'lng': 31.2357,
      },
      {
        'id': 'amman',
        'nameAr': 'عمّان',
        'nameEn': 'Amman',
        'lat': 31.9539,
        'lng': 35.9106,
      },
      {
        'id': 'benisuef',
        'nameAr': 'بنى سويف',
        'nameEn': 'Beni Suef',
        'lat': 29.0661,
        'lng': 31.0994,
      },
    ];

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = CityRepository(db: db, loader: () async => _rows());
  });

  tearDown(() async {
    await db.close();
  });

  test('plain-alef query finds the hamza-alef name', () async {
    expect((await repo.search('الاسكندرية')).single.id, 'alex');
    expect((await repo.search('الإسكندرية')).single.id, 'alex');
  });

  test('ha query finds the ta-marbuta name', () async {
    expect((await repo.search('القاهره')).single.id, 'cairo');
    expect((await repo.search('القاهرة')).single.id, 'cairo');
  });

  test('diacritics are ignored on both sides', () async {
    expect((await repo.search('عمان')).single.id, 'amman');
    expect((await repo.search('عمّان')).single.id, 'amman');
  });

  test('alef-maqsura and ya fold together', () async {
    expect((await repo.search('بني سويف')).single.id, 'benisuef');
    expect((await repo.search('بنى سويف')).single.id, 'benisuef');
  });

  test('latin search keeps case-insensitive trim behavior', () async {
    expect((await repo.search('  CAIRO ')).single.id, 'cairo');
    expect((await repo.search('alex')).single.id, 'alex');
  });

  test('whitespace-only query returns the whole catalog', () async {
    expect(await repo.search('   '), hasLength(4));
  });
}
