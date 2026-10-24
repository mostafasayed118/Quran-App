import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart'
    show BookmarkEntry;
import 'package:quran_yahdi/features/quran/data/ayah_source.dart';
import 'package:quran_yahdi/features/quran/data/last_read_source.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';

/// Last-read seam whose write always fails, to pin the safe-write path.
class _ThrowingLastRead implements LastReadSource {
  int saves = 0;

  @override
  Future<void> saveAyahId(int ayahId) async {
    saves += 1;
    throw StateError('last-read write failed');
  }

  @override
  Future<int?> loadAyahId() async => null;
}

/// Reader's ayah seam: two readable ayahs and a failing bookmark write.
class _ThrowingAyahs implements AyahSource {
  static const Ayah _first = Ayah(
    id: 1,
    surahId: 1,
    numberInSurah: 1,
    juz: 1,
    page: 1,
    textUthmani: 'بسم الله الرحمن الرحيم',
    textImlaei: 'بسم الله الرحمن الرحيم',
    sajda: false,
  );

  static const Ayah _second = Ayah(
    id: 2,
    surahId: 1,
    numberInSurah: 2,
    juz: 1,
    page: 1,
    textUthmani: 'الحمد لله رب العالمين',
    textImlaei: 'الحمد لله رب العالمين',
    sajda: false,
  );

  @override
  Future<List<Ayah>> surahAyahs(int surahId) async => const [_first, _second];

  @override
  Future<Surah?> surahById(int surahId) async => const Surah(
        id: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        revelationType: 'makkah',
        ayahCount: 2,
        pagesStart: 1,
        pagesEnd: 1,
      );

  @override
  Future<Ayah?> ayahById(int ayahId) async => null;

  @override
  Future<List<Ayah>> ayahsForRange(
          int surahId, int fromAyah, int toAyah) async =>
      const <Ayah>[];

  @override
  Future<void> toggleBookmark(int ayahId) async {
    throw StateError('bookmark write failed');
  }

  @override
  Future<void> deleteBookmark(int ayahId) async {}

  @override
  Stream<Set<int>> watchBookmarkedIds() => const Stream<Set<int>>.empty();

  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() =>
      const Stream<List<BookmarkEntry>>.empty();
}

void main() {
  late _ThrowingLastRead lastRead;

  ReaderCubit buildCubit() => ReaderCubit(
        ayahRepository: _ThrowingAyahs(),
        lastReadRepository: lastRead,
        surahId: 1,
        initialAyah: 1,
      );

  setUp(() {
    lastRead = _ThrowingLastRead();
  });

  test('a failing saveAyahId still reaches ready and stays handled', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);

    final ready = await cubit.stream
        .firstWhere((s) => s is ReaderReady)
        .timeout(const Duration(seconds: 10));

    expect(ready, isA<ReaderReady>());
    expect(lastRead.saves, 1,
        reason: 'the marker write is attempted once on load');
    // A stray unhandled async error would fail this test at teardown.
  });

  test('toggleBookmark completes when the repository write throws', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => s is ReaderReady);

    await cubit.toggleBookmark(1).timeout(const Duration(seconds: 10));

    expect(cubit.state, isA<ReaderReady>());
  });

  test('onMushafPageChanged completes when the marker write throws', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    final ready = await cubit.stream.firstWhere((s) => s is ReaderReady);
    expect((ready as ReaderReady).mushafPages, isNotEmpty);

    await cubit.onMushafPageChanged(0).timeout(const Duration(seconds: 10));

    expect(cubit.state, isA<ReaderReady>());
    expect(lastRead.saves, greaterThanOrEqualTo(2));
  });
}
