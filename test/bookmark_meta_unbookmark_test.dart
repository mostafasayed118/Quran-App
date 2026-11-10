import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta.dart';

import 'support/test_db.dart';

class _Meta implements BookmarkMetaSource {
  _Meta(this.entries);

  Map<int, BookmarkMetaEntry> entries;

  @override
  Future<Map<int, BookmarkMetaEntry>> load() async => Map.of(entries);

  @override
  Future<void> save(Map<int, BookmarkMetaEntry> value) async {
    entries = Map.of(value);
  }
}

Future<AppDatabase> _seededDb() async {
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
  return db;
}

const _entry = BookmarkMetaEntry(folder: 'Test3');

void main() {
  test('deleteBookmark removes the folder/note entry too', () async {
    final db = await _seededDb();
    final meta = _Meta({9: _entry});
    final repo = AyahRepository(db, meta: meta);

    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 9));
    await repo.deleteBookmark(9);

    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(meta.entries, isEmpty,
        reason: 'a folder must not outlive the bookmark it describes');
  });

  test('the reader star toggle also removes the entry when unbookmarking',
      () async {
    final db = await _seededDb();
    final meta = _Meta({9: _entry});
    final repo = AyahRepository(db, meta: meta);

    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 9));
    await repo.toggleBookmark(9);

    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(meta.entries, isEmpty);
  });

  test('bookmarking a new ayah keeps any pre-existing note for it', () async {
    final db = await _seededDb();
    final meta = _Meta({9: _entry});
    final repo = AyahRepository(db, meta: meta);

    await repo.toggleBookmark(9);

    expect(await db.select(db.bookmarks).get(), hasLength(1));
    expect(meta.entries[9], _entry);
  });
}
