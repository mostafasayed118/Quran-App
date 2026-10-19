import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/duas/data/dua_repository.dart';

List<Map<String, dynamic>> fixtureRows() => [
      {
        'id': 'a1',
        'categoryAr': 'المنزل',
        'categoryEn': 'Home',
        'text': 'بِسْمِ اللَّهِ وَلَجْنَا',
      },
      {
        'id': 'a2',
        'categoryAr': 'المنزل',
        'categoryEn': 'Home',
        'text': 'بِسْمِ اللَّهِ خَرَجْنَا',
      },
      {
        'id': 'a3',
        'categoryAr': 'السفر',
        'categoryEn': 'Travel',
        'text': 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا',
      },
    ];

void main() {
  late DuaRepository repo;

  setUp(() {
    repo = DuaRepository(loader: () async => fixtureRows());
  });

  test('parses entries and filters by category', () async {
    final entries = await repo.entries();
    expect(entries, hasLength(3));
    final home = await repo.byCategory('المنزل');
    expect(home, hasLength(2));
    final travel = await repo.byCategory('السفر');
    expect(travel.single.id, 'a3');
  });

  test('categories() returns unique non-empty category names', () async {
    final categories = await repo.categories();
    expect(categories, ['المنزل', 'السفر']);
  });

  test('bundled duas asset is well-formed (>=40 entries across >=6 categories)',
      () {
    final file = File('assets/data/duas.json');
    if (!file.existsSync()) {
      markTestSkipped(
          'working dir does not resolve the bundled asset from this runner');
    }
    final rows = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    expect(rows.length, greaterThanOrEqualTo(40));
    final categories = rows.map((r) => r['categoryAr'] as String).toSet();
    expect(categories.length, greaterThanOrEqualTo(6));
    for (final row in rows) {
      expect((row['text'] as String).trim().isNotEmpty, isTrue,
          reason: 'empty dua text in ${row['id']}');
      expect((row['categoryAr'] as String).isNotEmpty, isTrue);
    }
  });
}
