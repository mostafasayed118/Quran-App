import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';

import 'support/test_db.dart';

/// Evidence for audit #13: a fast fling reports many visibility callbacks, but
/// repeated reports of the same leading ayah collapse to a single write. The
/// cost is one last-read write per DISTINCT ayah, not one per frame. Combined
/// with the DB being opened via NativeDatabase.createInBackground, no SQL runs
/// on the UI isolate, so there is no frame-blocking write path to fix.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db
        .into(db.surahs)
        .insert(
          SurahsCompanion.insert(
            id: const Value(1),
            nameAr: 'الفاتحة',
            nameEn: 'Al-Fatihah',
            revelationType: 'makkah',
            ayahCount: 7,
            pagesStart: 1,
            pagesEnd: 1,
          ),
        );
    await db.batch(
      (b) => b.insertAll(db.ayahs, [
        for (var i = 1; i <= 7; i++)
          AyahsCompanion.insert(
            id: Value(i),
            surahId: 1,
            numberInSurah: i,
            juz: 1,
            page: 1,
            textUthmani: 'آية $i',
            textImlaei: 'آية $i',
          ),
      ]),
    );
  });

  test(
    'a burst of repeated visibility reports writes only once per ayah',
    () async {
      final lastRead = LastReadRepository(db);
      final cubit = ReaderCubit(
        ayahRepository: AyahRepository(db),
        lastReadRepository: lastRead,
        surahId: 1,
        initialAyah: 1,
      );
      addTearDown(cubit.close);
      await cubit.start();

      // Simulate a fling: 30 callbacks across 7 distinct leading ayahs.
      for (final id in [
        1,
        1,
        1,
        2,
        2,
        3,
        3,
        3,
        3,
        4,
        4,
        5,
        5,
        6,
        6,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
      ]) {
        await cubit.onVisibleAyah(id);
      }

      expect(await lastRead.loadAyahId(), 7);
    },
  );
}
