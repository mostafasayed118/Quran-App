import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/page_anchor_repository.dart';

import 'support/test_db.dart';

Future<void> _seed(AppDatabase db) async {
  await db.into(db.surahs).insert(
        SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'الفاتحة',
          nameEn: 'Al-Fatiha',
          revelationType: 'makki',
          ayahCount: 7,
          pagesStart: 1,
          pagesEnd: 1,
        ),
      );
  await db.into(db.surahs).insert(
        SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqara',
          revelationType: 'madani',
          ayahCount: 286,
          pagesStart: 2,
          pagesEnd: 49,
        ),
      );
  await db.into(db.ayahs).insert(
        AyahsCompanion.insert(
          id: const Value(1),
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'x',
          textImlaei: 'x',
        ),
      );
  await db.into(db.ayahs).insert(
        AyahsCompanion.insert(
          id: const Value(2),
          surahId: 2,
          numberInSurah: 1,
          juz: 30,
          page: 604,
          textUthmani: 'x',
          textImlaei: 'x',
        ),
      );
}

void main() {
  test('page anchors resolve the first ayah of a page from the database',
      () async {
    final db = newTestDb();
    await _seed(db);
    final repo = PageAnchorRepository(db);

    expect(await repo.anchorForPage(1), (surahId: 1, numberInSurah: 1));
    expect(await repo.anchorForPage(604), (surahId: 2, numberInSurah: 1));
  });

  test('page anchors reject out-of-range values', () async {
    final db = newTestDb();
    await _seed(db);
    final repo = PageAnchorRepository(db);

    expect(await repo.anchorForPage(0), isNull);
    expect(await repo.anchorForPage(605), isNull);
  });
}
