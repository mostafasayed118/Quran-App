import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_state.dart';

import 'support/test_db.dart';

Future<AppDatabase> _seed(int bookmarks) async {
  final db = newTestDb();
  await db.into(db.surahs).insert(SurahsCompanion.insert(
        id: const Value(1),
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        revelationType: 'makkah',
        ayahCount: bookmarks,
        pagesStart: 1,
        pagesEnd: 1,
      ));
  for (var id = 1; id <= bookmarks; id++) {
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: Value(id),
          surahId: 1,
          numberInSurah: id,
          juz: 1,
          page: 1,
          textUthmani: 'نص $id',
          textImlaei: 'نص $id',
        ));
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: id));
  }
  return db;
}

void main() {
  test('first page is newest-first and reports hasMore', () async {
    final db = await _seed(25);
    final repo = AyahRepository(db);

    final page = await repo.watchFirstPage(limit: 20).first;

    expect(page.entries, hasLength(20));
    expect(page.hasMore, true);
    expect(page.entries.first.ayah.id, 25);
    expect(page.entries.last.ayah.id, 6);
  });

  test('older page continues the keyset without duplicates', () async {
    final db = await _seed(25);
    final repo = AyahRepository(db);

    final first = await repo.watchFirstPage(limit: 20).first;
    final older =
        await repo.entriesBefore(first.entries.last.bookmarkId, limit: 20);

    expect(older.entries, hasLength(5));
    expect(older.hasMore, false);
    expect(older.entries.map((e) => e.ayah.id), [5, 4, 3, 2, 1]);
  });

  test('cubit appends older pages and keeps deletes local', () async {
    final db = await _seed(25);
    final repo = AyahRepository(db);
    final cubit = BookmarksCubit(repo, pager: repo);
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.stream.firstWhere((s) => s is BookmarksReady);
    expect((cubit.state as BookmarksReady).entries, hasLength(20));
    expect((cubit.state as BookmarksReady).hasMore, true);

    await cubit.loadMore();
    var state = cubit.state as BookmarksReady;
    expect(state.entries, hasLength(25));
    expect(state.hasMore, false);
    expect(state.entries.last.id, 1);

    await cubit.remove(1);
    await pumpEventQueue();

    state = cubit.state as BookmarksReady;
    expect(state.entries, hasLength(24));
    expect(state.entries.map((v) => v.id), isNot(contains(1)));
  });
}
