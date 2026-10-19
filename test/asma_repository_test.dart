import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/asma/data/asma_repository.dart';

List<Map<String, dynamic>> fixtureRows() => [
      {
        'n': 1,
        'nameAr': 'الرحمن',
        'nameEn': 'Ar-Rahman',
        'meaningAr': 'ذو الرحمة الواسعة',
        'meaningEn': 'The Most Compassionate',
      },
      {
        'n': 2,
        'nameAr': 'الرحيم',
        'nameEn': 'Ar-Raheem',
        'meaningAr': 'النازل بالرحمة',
        'meaningEn': 'The Most Merciful',
      },
    ];

void main() {
  late AsmaRepository repo;

  setUp(() {
    repo = AsmaRepository(loader: () async => fixtureRows());
  });

  test('parses entries ordered by n with all fields', () async {
    final names = await repo.names();
    expect(names, hasLength(2));
    expect(names[0].n, 1);
    expect(names[1].nameEn, 'Ar-Raheem');
    expect(names[1].meaningEn, 'The Most Merciful');
  });

  test('bundled asma asset carries EXACTLY 99 unique names n1..99', () {
    final file = File('assets/data/asma.json');
    if (!file.existsSync()) {
      markTestSkipped(
          'working dir does not resolve the bundled asset from this runner');
    }
    final rows = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    expect(rows.length, 99);
    final numbers = rows.map((r) => r['n'] as int).toList()..sort();
    expect(numbers, [for (var i = 1; i <= 99; i++) i]);
    for (final row in rows) {
      expect((row['nameAr'] as String).trim().isNotEmpty, isTrue,
          reason: 'nameAr empty at n=${row['n']}');
      expect((row['nameEn'] as String).trim().isNotEmpty, isTrue);
      expect((row['meaningAr'] as String).trim().isNotEmpty, isTrue);
      expect((row['meaningEn'] as String).trim().isNotEmpty, isTrue);
    }
  });
}
