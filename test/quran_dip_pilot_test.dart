import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_source.dart';
import 'package:quran_yahdi/features/quran/data/last_read_source.dart';
import 'package:quran_yahdi/features/quran/domain/verse.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';

/// Pure in-memory [AyahSource]: no `AppDatabase`, no drift runtime — the
/// DIP pilot's pole proof that the reader depends on the seam alone.
class _InMemoryAyahSource implements AyahSource {
  _InMemoryAyahSource({required this.surah, required this.rows});

  final Surah surah;
  final List<Ayah> rows;

  @override
  Future<List<Ayah>> surahAyahs(int surahId) async =>
      rows.where((a) => a.surahId == surahId).toList();

  @override
  Future<Surah?> surahById(int surahId) async =>
      surahId == surah.id ? surah : null;

  @override
  Future<Ayah?> ayahById(int ayahId) async {
    for (final row in rows) {
      if (row.id == ayahId) return row;
    }
    return null;
  }

  @override
  Future<List<Ayah>> ayahsForRange(
          int surahId, int fromAyah, int toAyah) async =>
      rows
          .where((a) =>
              a.surahId == surahId &&
              a.numberInSurah >= fromAyah &&
              a.numberInSurah <= toAyah)
          .toList();

  @override
  Future<void> toggleBookmark(int ayahId) async {}

  @override
  Future<void> deleteBookmark(int ayahId) async {}

  @override
  Stream<Set<int>> watchBookmarkedIds() => Stream.value(const <int>{});

  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() =>
      Stream.value(const <BookmarkEntry>[]);
}

class _InMemoryLastReadSource implements LastReadSource {
  int? saved;

  @override
  Future<void> saveAyahId(int ayahId) async => saved = ayahId;

  @override
  Future<int?> loadAyahId() async => saved;
}

const _surah = Surah(
  id: 2,
  nameAr: 'البقرة',
  nameEn: 'Al-Baqarah',
  revelationType: 'madinah',
  ayahCount: 3,
  pagesStart: 2,
  pagesEnd: 3,
);

const _baqarah = [
  Ayah(
      id: 8,
      surahId: 2,
      numberInSurah: 1,
      juz: 1,
      page: 2,
      textUthmani: 'الم',
      textImlaei: 'الم',
      sajda: false),
  Ayah(
      id: 9,
      surahId: 2,
      numberInSurah: 2,
      juz: 1,
      page: 2,
      textUthmani: 'ذلك الكتاب',
      textImlaei: 'ذلك الكتاب',
      sajda: false),
  Ayah(
      id: 10,
      surahId: 2,
      numberInSurah: 3,
      juz: 1,
      page: 3,
      textUthmani: 'الذين يؤمنون',
      textImlaei: 'الذين يؤمنون',
      sajda: true),
];

void main() {
  test('reader ready carries mapped Verses from pure seam fakes (no database)',
      () async {
    final lastRead = _InMemoryLastReadSource();
    final cubit = ReaderCubit(
      ayahRepository: _InMemoryAyahSource(surah: _surah, rows: _baqarah),
      lastReadRepository: lastRead,
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);

    final ready =
        await cubit.stream.firstWhere((s) => s is ReaderReady) as ReaderReady;

    expect(ready.surahName, 'البقرة');
    expect(ready.ayahs, hasLength(3));
    expect(ready.ayahs, everyElement(isA<Verse>()));
    expect(ready.ayahs.map((v) => v.textImlaei).toList(),
        ['الم', 'ذلك الكتاب', 'الذين يؤمنون']);
    expect(ready.ayahs.last.sajda, isTrue);
    expect(ready.mushafPages.map((b) => b.page).toList(), [2, 3]);
    expect(ready.mushafPages.first.ayahs, everyElement(isA<Verse>()));
    expect(ready.mushafPages.first.ayahs.map((v) => v.numberInSurah).toList(),
        [1, 2]);
    expect(lastRead.saved, 8,
        reason: 'initial ayah 0 falls back to the surah first row id');
  });

  test('the initial ayah resolves through the seam to its row id', () async {
    final lastRead = _InMemoryLastReadSource();
    final cubit = ReaderCubit(
      ayahRepository: _InMemoryAyahSource(surah: _surah, rows: _baqarah),
      lastReadRepository: lastRead,
      surahId: 2,
      initialAyah: 2,
    );
    addTearDown(cubit.close);

    final ready =
        await cubit.stream.firstWhere((s) => s is ReaderReady) as ReaderReady;

    expect(ready.initialAyah, 2);
    expect(lastRead.saved, 9);
  });
}
