import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';

import 'support/test_db.dart';

List<Map<String, dynamic>> fixtureRows() => [
      {'id': 'f1', 'kind': 'dhikr', 'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ', 'count': 3},
      {'id': 'f2', 'kind': 'quran', 'surahId': 112, 'fromAyah': 1, 'toAyah': 4},
    ];

void main() {
  late AppDatabase db;
  late RuqyahRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = RuqyahRepository(loader: () async => fixtureRows());
    await db.into(db.surahs).insert(SurahsCompanion.insert(
      id: const Value(112),
      nameAr: 'الإخلاص',
      nameEn: 'Al-Ikhlas',
      revelationType: 'Meccan',
      ayahCount: 4,
      pagesStart: 604,
      pagesEnd: 604,
    ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
      id: const Value(6220),
      surahId: 112,
      numberInSurah: 1,
      juz: 30,
      page: 604,
      textUthmani: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      textImlaei: 'قل هو الله أحد',
    ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
      id: const Value(6221),
      surahId: 112,
      numberInSurah: 2,
      juz: 30,
      page: 604,
      textUthmani: 'اللَّهُ الصَّمَدُ',
      textImlaei: 'الله الصمد',
    ));
  });

  test('parses entries; dhikr passes through, quran carries ranges', () async {
    final entries = await repo.entries();
    expect(entries, hasLength(2));
    expect(entries[0].kind, 'dhikr');
    expect(entries[0].text, isNotNull);
    expect(entries[1].kind, 'quran');
    expect(entries[1].surahId, 112);
    expect(entries[1].fromAyah, 1);
    expect(entries[1].toAyah, 4);
  });

  test('bundled ruqyah asset carries complete quran ranges (>=8 entries)', () {
    final file = File('assets/data/ruqyah.json');
    if (!file.existsSync()) {
      markTestSkipped(
          'working dir does not resolve the bundled asset from this runner');
    }
    final rows =
        (jsonDecode(file.readAsStringSync()) as List)
            .cast<Map<String, dynamic>>();
    expect(rows.length, greaterThanOrEqualTo(8));
    for (final row in rows) {
      if (row['kind'] == 'quran') {
        expect(row['surahId'], isNotNull, reason: '${row['id']}');
        expect(row['fromAyah'], isNotNull);
        expect(row['toAyah'], isNotNull);
        expect(row['text'], isNull,
            reason: 'quran text must come from the DB, never JSON');
      } else {
        expect((row['text'] as String).trim().isNotEmpty, isTrue);
      }
    }
  });
}
