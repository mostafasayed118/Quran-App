import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/folder_bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/folder_bookmarks_state.dart';

class _Meta implements BookmarkMetaSource {
  _Meta(this.entries);

  final Map<int, BookmarkMetaEntry> entries;

  @override
  Future<Map<int, BookmarkMetaEntry>> load() async => entries;

  @override
  Future<void> save(Map<int, BookmarkMetaEntry> next) async {}
}

class _Lookup implements AyahLookup {
  _Lookup(this.rows);

  final Map<int, Ayah> rows;

  @override
  Future<Ayah?> ayahById(int ayahId) async => rows[ayahId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Ayah _ayah(int id, int surah, int number, String text) => Ayah(
      id: id,
      surahId: surah,
      numberInSurah: number,
      juz: 1,
      page: 1,
      textUthmani: text,
      textImlaei: text,
      sajda: false,
    );

void main() {
  test('loads the folder items in surah/ayah order with their notes', () async {
    final cubit = FolderBookmarksCubit(
      folder: 'تفسير',
      meta: _Meta({
        9: const BookmarkMetaEntry(folder: 'تفسير', note: 'الثانية'),
        8: const BookmarkMetaEntry(folder: 'تفسير', note: 'الأولى'),
        7: const BookmarkMetaEntry(folder: 'أذكار'),
      }),
      ayahs: _Lookup({
        8: _ayah(8, 2, 1, 'الم'),
        9: _ayah(9, 2, 2, 'ذلك الكتاب'),
      }),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as FolderBookmarksReady;
    expect(ready.folder, 'تفسير');
    expect(ready.items, hasLength(2));
    expect(ready.items.first.verse.numberInSurah, 1);
    expect(ready.items.first.note, 'الأولى');
    expect(ready.items.last.verse.numberInSurah, 2);
  });

  test('an ayah missing from the database is skipped', () async {
    final cubit = FolderBookmarksCubit(
      folder: 'تفسير',
      meta: _Meta({
        9: const BookmarkMetaEntry(folder: 'تفسير'),
      }),
      ayahs: _Lookup(const {}),
    );
    addTearDown(cubit.close);

    await cubit.start();

    expect((cubit.state as FolderBookmarksReady).items, isEmpty);
  });

  test('a folder with no entries is ready and empty', () async {
    final cubit = FolderBookmarksCubit(
      folder: 'غير موجود',
      meta: _Meta({
        9: const BookmarkMetaEntry(folder: 'تفسير'),
      }),
      ayahs: _Lookup(const {}),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as FolderBookmarksReady;
    expect(ready.folder, 'غير موجود');
    expect(ready.items, isEmpty);
  });
}
