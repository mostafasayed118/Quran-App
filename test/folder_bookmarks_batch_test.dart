import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/ayah_batch_lookup.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/folder_bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/folder_bookmarks_state.dart';

/// The folder list used to resolve each bookmark with its own await — one
/// serialized background-isolate round-trip per row. The batch port fixes that,
/// but it must actually be used, and the per-id path must keep working for the
/// frozen doubles that only implement `AyahLookup`.

class _Meta implements BookmarkMetaSource {
  _Meta(this.entries);

  final Map<int, BookmarkMetaEntry> entries;

  @override
  Future<Map<int, BookmarkMetaEntry>> load() async => entries;

  @override
  Future<void> save(Map<int, BookmarkMetaEntry> next) async {}
}

class _Single implements AyahLookup {
  _Single(this.rows);
  final Map<int, Ayah> rows;
  int calls = 0;

  @override
  Future<Ayah?> ayahById(int ayahId) async {
    calls++;
    return rows[ayahId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingBatch implements AyahBatchLookup {
  _CountingBatch(this.rows);
  final Map<int, Ayah> rows;
  int calls = 0;
  List<int> lastIds = const [];

  @override
  Future<List<Ayah>> ayahsByIds(List<int> ids) async {
    calls++;
    lastIds = ids;
    return [
      for (final id in ids)
        if (rows[id] case final row?) row,
    ];
  }
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
  final meta = _Meta({
    8: const BookmarkMetaEntry(folder: 'تفسير', note: 'الأولى'),
    9: const BookmarkMetaEntry(folder: 'تفسير', note: 'الثانية'),
  });

  test('the batch port resolves the folder in ONE call', () async {
    final single = _Single(const {});
    final batch = _CountingBatch({
      8: _ayah(8, 2, 1, 'الم'),
      9: _ayah(9, 2, 2, 'ذلك الكتاب'),
    });
    final cubit = FolderBookmarksCubit(
      folder: 'تفسير',
      meta: meta,
      ayahs: single,
      batch: batch,
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as FolderBookmarksReady;
    expect(ready.items, hasLength(2));
    expect(ready.items.first.note, 'الأولى');
    expect(batch.calls, 1, reason: 'one query for the whole folder');
    expect(batch.lastIds.toSet(), {8, 9});
    expect(single.calls, 0, reason: 'the per-id loop must not also run');
  });

  test('without the batch port the per-id path still resolves the folder',
      () async {
    final single = _Single({
      8: _ayah(8, 2, 1, 'الم'),
      9: _ayah(9, 2, 2, 'ذلك الكتاب'),
    });
    final cubit = FolderBookmarksCubit(
      folder: 'تفسير',
      meta: meta,
      ayahs: single,
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as FolderBookmarksReady;
    expect(ready.items, hasLength(2));
    expect(ready.items.last.note, 'الثانية');
    expect(single.calls, 2, reason: 'frozen doubles keep the old path');
  });
}
