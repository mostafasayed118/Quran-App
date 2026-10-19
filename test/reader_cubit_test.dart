import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late AyahRepository ayahs;
  late LastReadRepository lastRead;

  setUp(() async {
    db = newTestDb();
    final fatiha = [
      AyahsCompanion.insert(
          id: const Value(1),
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'بسم الله الرحمن الرحيم',
          textImlaei: 'بسم الله الرحمن الرحيم'),
      AyahsCompanion.insert(
          id: const Value(2),
          surahId: 1,
          numberInSurah: 2,
          juz: 1,
          page: 1,
          textUthmani: 'الحمد لله رب العالمين',
          textImlaei: 'الحمد لله رب العالمين'),
      AyahsCompanion.insert(
          id: const Value(3),
          surahId: 1,
          numberInSurah: 3,
          juz: 1,
          page: 1,
          textUthmani: 'الرحمن الرحيم',
          textImlaei: 'الرحمن الرحيم'),
    ];
    final baqarah = [
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
    ];
    await db.batch((b) => b.insertAll(db.ayahs, fatiha));
    await db.batch((b) => b.insertAll(db.ayahs, baqarah));
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
              id: const Value(1),
              nameAr: 'الفاتحة',
              nameEn: 'Al-Fatihah',
              revelationType: 'makkah',
              ayahCount: 3,
              pagesStart: 1,
              pagesEnd: 1),
        );
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
              id: const Value(2),
              nameAr: 'البقرة',
              nameEn: 'Al-Baqarah',
              revelationType: 'madinah',
              ayahCount: 2,
              pagesStart: 2,
              pagesEnd: 2),
        );
    ayahs = AyahRepository(db);
    lastRead = LastReadRepository(db);
  });

  test('loads ready state; basmala banner policy per surah', () async {
    ReaderCubit? cubit = ReaderCubit(
        ayahRepository: ayahs,
        lastReadRepository: lastRead,
        surahId: 2,
        initialAyah: 0);
    final ready =
        await cubit.stream.firstWhere((s) => s is ReaderReady) as ReaderReady;
    expect(ready.showBasmala, isTrue);
    expect(ready.surahName, 'البقرة');
    expect(ready.mushafPages, isNotEmpty);
    await cubit.close();

    cubit = ReaderCubit(
        ayahRepository: ayahs,
        lastReadRepository: lastRead,
        surahId: 1,
        initialAyah: 0);
    final fatihaReady =
        await cubit.stream.firstWhere((s) => s is ReaderReady) as ReaderReady;
    expect(fatihaReady.showBasmala, isFalse);
    await cubit.close();
  });

  test('toggleBookmark flips the bookmarkedIds set (via watch)', () async {
    final cubit = ReaderCubit(
        ayahRepository: ayahs,
        lastReadRepository: lastRead,
        surahId: 2,
        initialAyah: 0);
    await cubit.stream.firstWhere((s) => s is ReaderReady);
    await cubit.toggleBookmark(8);
    await cubit.stream.firstWhere(
        (s) => s is ReaderReady && (s).bookmarkedAyahIds.contains(8));
    await cubit.toggleBookmark(8);
    await cubit.stream.firstWhere(
        (s) => s is ReaderReady && !(s).bookmarkedAyahIds.contains(8));
    await cubit.close();
  });

  test('toggleMode flips verses <-> mushaf; page change persists last-read',
      () async {
    final cubit = ReaderCubit(
        ayahRepository: ayahs,
        lastReadRepository: lastRead,
        surahId: 2,
        initialAyah: 0);
    final ready =
        await cubit.stream.firstWhere((s) => s is ReaderReady) as ReaderReady;
    expect(ready.mode, ReaderMode.verses);
    cubit.toggleMode();
    final mushaf = cubit.state as ReaderReady;
    expect(mushaf.mode, ReaderMode.mushaf);
    await cubit.onMushafPageChanged(0);
    expect(await lastRead.loadAyahId(), 8);
    await cubit.close();
  });
}
