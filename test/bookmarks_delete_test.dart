import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_state.dart';

import 'support/test_db.dart';

void main() {
  test('removing a bookmark twice never re-adds it', () async {
    final db = newTestDb();
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
            id: const Value(2),
            nameAr: 'البقرة',
            nameEn: 'Al-Baqarah',
            revelationType: 'madani',
            ayahCount: 286,
            pagesStart: 2,
            pagesEnd: 49,
          ),
        );
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(9),
            surahId: 2,
            numberInSurah: 2,
            juz: 1,
            page: 2,
            textUthmani: 'ذلك الكتاب',
            textImlaei: 'ذلك الكتاب',
          ),
        );
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 9));

    final cubit = BookmarksCubit(AyahRepository(db));
    addTearDown(cubit.close);

    await cubit.stream
        .firstWhere((s) => s is BookmarksReady)
        .timeout(const Duration(seconds: 10));
    expect((cubit.state as BookmarksReady).entries, hasLength(1));

    final emptied = cubit.stream
        .firstWhere((s) => s is BookmarksReady && s.entries.isEmpty)
        .timeout(const Duration(seconds: 10));

    await cubit.remove(9);
    await cubit.remove(9);

    await emptied;
    expect(await db.select(db.bookmarks).get(), isEmpty,
        reason: 'the second delete must not toggle the bookmark back in');
    expect((cubit.state as BookmarksReady).entries, isEmpty);
  });
}
