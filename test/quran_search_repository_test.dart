import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/search_index.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_repository.dart';

import 'support/test_db.dart';

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

  test('finds an ayah despite diacritics in the query', () async {
    final page = await repo.search('الصَّلَاة');
    expect(page.hits.map((h) => h.ayahId), [2, 3]);
    expect(page.total, 2);
  });

  test('folds alef and ta marbuta variants', () async {
    final alef = await repo.search('الاسلام');
    expect(alef.hits.single.ayahId, 4);
    final ta = await repo.search('الرحمه');
    expect(ta.hits.map((h) => h.ayahId), [4]);
  });

  test('requires every token (AND semantics)', () async {
    final page = await repo.search('الصلاة الزكاة');
    expect(page.hits.single.ayahId, 3);
  });

  test('drops punctuation from the query', () async {
    final page = await repo.search('الصلاة، الزكاة.');
    expect(page.hits.single.ayahId, 3);
  });

  test('short query returns an empty page without a query', () async {
    final page = await repo.search('ا');
    expect(page.hits, isEmpty);
    expect(page.total, 0);
    expect(page.hasMore, false);
  });

  test('pages by keyset cursor in mushaf order without duplicates', () async {
    final first = await repo.search('الصلاة', limit: 1);
    expect(first.hits.single.ayahId, 2);
    expect(first.hasMore, true);
    expect(first.total, 2);

    final second = await repo.search('الصلاة',
        afterAyahId: first.hits.last.ayahId, limit: 1);
    expect(second.hits.single.ayahId, 3);
    expect(second.hasMore, false);

    final third = await repo.search('الصلاة',
        afterAyahId: second.hits.last.ayahId, limit: 1);
    expect(third.hits, isEmpty);
  });
}
