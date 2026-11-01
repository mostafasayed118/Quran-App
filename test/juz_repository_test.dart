import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/juz_repository.dart';
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
  await db.batch((batch) {
    for (var juz = 1; juz <= 30; juz++) {
      batch.insert(
        db.ayahs,
        AyahsCompanion.insert(
          id: Value(juz),
          surahId: 1,
          numberInSurah: juz,
          juz: juz,
          page: juz * 20,
          textUthmani: 'x',
          textImlaei: 'x',
        ),
      );
    }
    batch.insert(
      db.ayahs,
      AyahsCompanion.insert(
        id: const Value(31),
        surahId: 2,
        numberInSurah: 1,
        juz: 30,
        page: 604,
        textUthmani: 'x',
        textImlaei: 'x',
      ),
    );
  });
}

void main() {
  test('the juz repository derives 30 starts from the ayah table', () async {
    final db = newTestDb();
    await _seed(db);

    final juz = await JuzRepository(db).watchJuz().first;

    expect(juz, hasLength(30));
    expect(juz.first.juz, 1);
    expect(juz.first.firstPage, 20);
    expect(juz.first.surahName, 'الفاتحة');
    expect(juz.last.juz, 30);
    expect(juz.last.firstPage, 600);
  });

  test('page anchors resolve the first ayah on a page', () async {
    final db = newTestDb();
    await _seed(db);
    final repo = PageAnchorRepository(db);

    expect(await repo.anchorForPage(1), isNull);
    expect(
      await repo.anchorForPage(604),
      (surahId: 2, numberInSurah: 1),
    );
    expect(await repo.anchorForPage(0), isNull);
    expect(await repo.anchorForPage(605), isNull);
  });
}
