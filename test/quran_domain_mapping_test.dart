import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/verse_mapping.dart';
import 'package:quran_yahdi/features/quran/domain/surah_summary.dart';
import 'package:quran_yahdi/features/quran/domain/verse.dart';

void main() {
  test('toVerse round-trips every carried field of the row', () {
    const row = Ayah(
      id: 9,
      surahId: 2,
      numberInSurah: 2,
      juz: 1,
      page: 2,
      lineStart: 4,
      lineEnd: 5,
      textUthmani: 'ذلك الكتاب',
      textImlaei: 'ذلك الكتاب',
      sajda: false,
    );

    final verse = row.toVerse();

    expect(verse, isA<Verse>());
    expect(verse.id, row.id);
    expect(verse.surahId, row.surahId);
    expect(verse.numberInSurah, row.numberInSurah);
    expect(verse.juz, row.juz);
    expect(verse.page, row.page);
    expect(verse.textUthmani, row.textUthmani);
    expect(verse.textImlaei, row.textImlaei);
    expect(verse.sajda, isFalse);
  });

  test('sajda true survives the mapping (the row column is non-nullable)', () {
    const row = Ayah(
      id: 6205,
      surahId: 96,
      numberInSurah: 19,
      juz: 30,
      page: 597,
      textUthmani: 'كَلَّا لَا تُطِعْهُ',
      textImlaei: 'كلا لا تطعه',
      sajda: true,
    );

    expect(row.toVerse().sajda, isTrue);
  });

  test('toSummary round-trips every field of the surah row', () {
    const row = Surah(
      id: 2,
      nameAr: 'البقرة',
      nameEn: 'Al-Baqarah',
      revelationType: 'madinah',
      ayahCount: 286,
      pagesStart: 2,
      pagesEnd: 49,
    );

    final summary = row.toSummary();

    expect(summary, isA<SurahSummary>());
    expect(summary.id, row.id);
    expect(summary.nameAr, row.nameAr);
    expect(summary.nameEn, row.nameEn);
    expect(summary.revelationType, row.revelationType);
    expect(summary.ayahCount, row.ayahCount);
    expect(summary.pagesStart, row.pagesStart);
    expect(summary.pagesEnd, row.pagesEnd);
  });
}
