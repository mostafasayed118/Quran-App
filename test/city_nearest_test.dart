import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';

import 'support/test_db.dart';

City city(String id, String nameAr, String nameEn, double lat, double lng) =>
    City(id: id, nameAr: nameAr, nameEn: nameEn, lat: lat, lng: lng);

void main() {
  late AppDatabase db;
  late CityRepository repo;
  late List<City> catalog;

  setUp(() async {
    db = newTestDb();
    catalog = [
      city('cairo', 'القاهرة', 'Cairo', 30.0444, 31.2357),
      city('giza', 'الجيزة', 'Giza', 30.0131, 31.2089),
      city('alex', 'الإسكندرية', 'Alexandria', 31.2001, 29.9187),
      city('aswan', 'أسوان', 'Aswan', 24.0889, 32.8998),
      city('riyadh', 'الرياض', 'Riyadh', 24.7136, 46.6753),
    ];
    repo = CityRepository(
        db: db, loader: () async => [for (final c in catalog) c.toJson()]);
  });

  test('point between Cairo and Giza picks the mathematically nearest',
      () async {
    final nearest = await repo.nearestTo(30.05, 31.22);
    expect(nearest.id, 'cairo');
  });

  test('point near Aswan picks Aswan, not the far Riyadh', () async {
    final nearest = await repo.nearestTo(24.2, 32.8);
    expect(nearest.id, 'aswan');
  });

  test('query exactly at a city returns that city', () async {
    final nearest = await repo.nearestTo(31.2001, 29.9187);
    expect(nearest.id, 'alex');
  });
}
