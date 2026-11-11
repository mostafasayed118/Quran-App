import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';

void main() {
  const city = City(
    id: 'eg-cairo',
    nameAr: 'القاهرة',
    nameEn: 'Cairo',
    lat: 30.0444,
    lng: 31.2357,
  );

  test('Arabic picks nameAr and English picks nameEn', () {
    expect(cityDisplayName(city, 'ar'), 'القاهرة');
    expect(cityDisplayName(city, 'en'), 'Cairo');
  });

  test('any unknown locale falls back to English', () {
    expect(cityDisplayName(city, 'fr'), 'Cairo');
  });
}
