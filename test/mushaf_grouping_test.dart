import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/mushaf_page_block.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    final ayahs = [
      AyahsCompanion.insert(
          id: const Value(8), surahId: 2, numberInSurah: 1, juz: 1, page: 2,
          textUthmani: 'الم', textImlaei: 'الم'),
      AyahsCompanion.insert(
          id: const Value(9), surahId: 2, numberInSurah: 2, juz: 1, page: 2,
          textUthmani: 'ذلك الكتاب', textImlaei: 'ذلك الكتاب'),
      AyahsCompanion.insert(
          id: const Value(10), surahId: 2, numberInSurah: 3, juz: 1, page: 3,
          textUthmani: 'الذين يؤمنون', textImlaei: 'الذين يؤمنون'),
      AyahsCompanion.insert(
          id: const Value(11), surahId: 2, numberInSurah: 4, juz: 1, page: 4,
          textUthmani: 'وبما رزقناهم', textImlaei: 'وبما رزقناهم'),
      AyahsCompanion.insert(
          id: const Value(12), surahId: 2, numberInSurah: 5, juz: 1, page: 4,
          textUthmani: 'وبالآخرة هم يقينون', textImlaei: 'وبالآخرة هم يقينون'),
      AyahsCompanion.insert(
          id: const Value(13), surahId: 2, numberInSurah: 6, juz: 1, page: 4,
          textUthmani: 'أولئك على هدى', textImlaei: 'أولئك على هدى'),
    ];
    await db.batch((b) => b.insertAll(db.ayahs, ayahs));
  });

  tearDown(() async => db.close());

  test('groups surah ayahs into sorted page blocks', () async {
    final repo = AyahRepository(db);
    final blocks = groupAyahsByPage(await repo.surahAyahs(2));

    expect(blocks.map((b) => b.page).toList(), [2, 3, 4]);
    expect(blocks.map((b) => b.ayahs.length).toList(), [2, 1, 3]);
    expect(blocks.first.ayahs.first.numberInSurah, 1);
  });
}
