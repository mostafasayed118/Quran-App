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
        ayahCount: 3,
        pagesStart: 1,
        pagesEnd: 1,
      ));
  final texts = <(int, int, String)>[
    (1, 1, 'ويقيمون الصلاة'),
    (2, 2, 'وأقيموا الصلاة وآتوا الزكاة'),
    (3, 3, 'إن الصلاة تنهى عن الفحشاء'),
  ];
  for (final (id, number, text) in texts) {
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: Value(id),
          surahId: 1,
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
  group('SearchTotalCache', () {
    test('a stored signature is served back', () {
      final cache = SearchTotalCache()..store('الصلاة', 12);

      expect(cache.lookup('الصلاة'), 12);
    });

    test('another signature misses', () {
      final cache = SearchTotalCache()..store('الصلاة', 12);

      expect(cache.lookup('الزكاة'), isNull);
    });

    test('storing a new signature replaces the entry', () {
      final cache = SearchTotalCache()
        ..store('الصلاة', 12)
        ..store('الزكاة', 3);

      expect(cache.lookup('الزكاة'), 3);
      expect(cache.lookup('الصلاة'), isNull);
    });
  });

  test('paging keeps the first page total without rescanning the index',
      () async {
    final db = newTestDb();
    await _seed(db);
    final repo = QuranSearchRepository(db);

    final first = await repo.search('الصلاة', limit: 2);
    expect(first.total, 3);
    expect(first.hasMore, isTrue);

    // Content is static in production; mutating it here proves the later page
    // reuses the memoized total instead of running another COUNT scan.
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(4),
          surahId: 1,
          numberInSurah: 4,
          juz: 1,
          page: 1,
          textUthmani: 'الصلاة',
          textImlaei: 'الصلاة',
        ));
    await rebuildQuranSearchIndex(db);

    final second = await repo.search(
      'الصلاة',
      afterAyahId: first.hits.last.ayahId,
      limit: 2,
    );
    expect(second.total, 3);
  });

  test('a different query counts on its own', () async {
    final db = newTestDb();
    await _seed(db);
    final repo = QuranSearchRepository(db);

    expect((await repo.search('الصلاة')).total, 3);
    expect((await repo.search('الزكاة')).total, 1);
  });
}
