import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/search_index.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_repository.dart';

import 'support/test_db.dart';

/// Regression coverage for the short-token search regression.
///
/// The FTS5 `trigram` tokenizer cannot represent a token shorter than three
/// characters: it matches nothing AND is dropped from the MATCH expression,
/// so an AND across tokens silently degraded into the longer tokens alone.
/// The corpus below is the same four ayahs the search repository test seeds,
/// and the expectations are read off those exact texts:
///
///   1  بسم الله الرحمن الرحيم
///   2  الذين يؤمنون بالغيب ويقيمون الصلاة
///   3  وأقيموا الصلاة وآتوا الزكاة
///   4  إن الإسلام دين الرحمة
Future<void> _seed(AppDatabase db) async {
  await db.into(db.surahs).insert(SurahsCompanion.insert(
        id: const Value(1),
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        revelationType: 'makkah',
        ayahCount: 2,
        pagesStart: 1,
        pagesEnd: 1,
      ));
  await db.into(db.surahs).insert(SurahsCompanion.insert(
        id: const Value(2),
        nameAr: 'البقرة',
        nameEn: 'Al-Baqarah',
        revelationType: 'madani',
        ayahCount: 2,
        pagesStart: 2,
        pagesEnd: 2,
      ));
  final texts = <(int, int, int, String)>[
    (1, 1, 1, 'بسم الله الرحمن الرحيم'),
    (2, 2, 1, 'الذين يؤمنون بالغيب ويقيمون الصلاة'),
    (3, 2, 2, 'وأقيموا الصلاة وآتوا الزكاة'),
    (4, 2, 3, 'إن الإسلام دين الرحمة'),
  ];
  for (final (id, surahId, number, text) in texts) {
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: Value(id),
          surahId: surahId,
          numberInSurah: number,
          juz: 1,
          page: 1,
          textUthmani: text,
          textImlaei: text,
        ));
  }
  await rebuildQuranSearchIndex(db);
}

void main() {
  late AppDatabase db;
  late QuranSearchRepository repo;

  setUp(() async {
    db = newTestDb();
    await _seed(db);
    repo = QuranSearchRepository(db);
  });

  test('a two-character token still finds the ayahs that contain it', () async {
    // 'من' is inside 'الرحمن' (ayah 1) and 'يؤمنون' (ayah 2).
    final page = await repo.search('من');
    expect(page.hits.map((h) => h.ayahId), [1, 2]);
    expect(page.total, 2);
  });

  test('a short token is ANDed with the long ones, not dropped from it',
      () async {
    // 'من' is in ayahs 1 and 2; 'الصلاة' is in ayahs 2 and 3. The AND is
    // ayah 2 alone — dropping the short token would widen it to ayahs 2 AND 3.
    final page = await repo.search('من الصلاة');
    expect(page.hits.map((h) => h.ayahId), [2]);
    expect(page.total, 1);
  });

  test('a short token that matches nothing still empties the result', () async {
    // 'يا' is in none of the four ayahs, so the AND has no hit.
    final page = await repo.search('يا الصلاة');
    expect(page.hits, isEmpty);
    expect(page.total, 0);
  });

  test('the long-token path is unchanged', () async {
    final page = await repo.search('الصلاة');
    expect(page.hits.map((h) => h.ayahId), [2, 3]);
    expect(page.total, 2);
  });

  test('a one-character query is still rejected before any scan', () async {
    final page = await repo.search('ا');
    expect(page.hits, isEmpty);
    expect(page.total, 0);
  });
}
