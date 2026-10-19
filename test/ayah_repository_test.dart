import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late AyahRepository repo;

  setUp(() async {
    db = newTestDb();
    final ayahs = [
      AyahsCompanion.insert(
          id: const Value(8),
          surahId: 2,
          numberInSurah: 1,
          juz: 1,
          page: 2,
          textUthmani: 'الم',
          textImlaei: 'الم'),
      AyahsCompanion.insert(
          id: const Value(9),
          surahId: 2,
          numberInSurah: 2,
          juz: 1,
          page: 2,
          textUthmani: 'ذلك الكتاب',
          textImlaei: 'ذلك الكتاب'),
      AyahsCompanion.insert(
          id: const Value(10),
          surahId: 2,
          numberInSurah: 3,
          juz: 1,
          page: 3,
          textUthmani: 'الذين يؤمنون',
          textImlaei: 'الذين يؤمنون'),
    ];
    await db.batch((b) => b.insertAll(db.ayahs, ayahs));
    repo = AyahRepository(db);
  });

  test('surahAyahs returns the surah ordered by numberInSurah', () async {
    final list = await repo.surahAyahs(2);
    expect(list.map((a) => a.numberInSurah).toList(), [1, 2, 3]);
    expect(list.first.textImlaei, 'الم');
  });

  test('toggleBookmark inserts then removes', () async {
    await repo.toggleBookmark(9);
    expect((await repo.watchBookmarkedIds().first), contains(9));

    await repo.toggleBookmark(9);
    expect((await repo.watchBookmarkedIds().first), isNot(contains(9)));
  });

  test('watchBookmarkEntries joins ayah rows', () async {
    await repo.toggleBookmark(10);
    final entries = await repo.watchBookmarkEntries().first;
    expect(entries, hasLength(1));
    expect(entries.single.ayah.surahId, 2);
    expect(entries.single.ayah.numberInSurah, 3);
  });
}
