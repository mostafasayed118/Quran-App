import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';

import 'support/test_db.dart';

Future<AppDatabase> _seededDb() async {
  final db = newTestDb();
  await db.into(db.surahs).insert(
        SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'madani',
          ayahCount: 3,
          pagesStart: 2,
          pagesEnd: 3,
        ),
      );
  for (final (id, number, page) in [(8, 1, 2), (9, 2, 2), (10, 3, 3)]) {
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: Value(id),
            surahId: 2,
            numberInSurah: number,
            juz: 1,
            page: page,
            textUthmani: 'ayah $number',
            textImlaei: 'ayah $number',
          ),
        );
  }
  return db;
}

void main() {
  test('opening a surah does not overwrite the stored last-read marker',
      () async {
    final db = await _seededDb();
    final lastRead = LastReadRepository(db);
    await lastRead.saveAyahId(9);

    final cubit = ReaderCubit(
      ayahRepository: AyahRepository(db),
      lastReadRepository: lastRead,
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);
    final readyFuture = cubit.stream.firstWhere((s) => s is ReaderReady);
    await cubit.start();
    final ready = await readyFuture as ReaderReady;

    expect(ready.currentAyahId, 8);
    expect(await lastRead.loadAyahId(), 9,
        reason: 'a glance at the surah must not rewind continue-reading');
  });

  test('the reading anchor survives both mode switches', () async {
    final db = await _seededDb();
    final lastRead = LastReadRepository(db);
    final cubit = ReaderCubit(
      ayahRepository: AyahRepository(db),
      lastReadRepository: lastRead,
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);
    final readyFuture = cubit.stream.firstWhere((s) => s is ReaderReady);
    await cubit.start();
    await readyFuture;

    await cubit.onVisibleAyah(10);
    expect(await lastRead.loadAyahId(), 10);
    cubit.toggleMode();
    expect((cubit.state as ReaderReady).currentAyahId, 10,
        reason: 'verses -> mushaf must stay on the visible ayah');

    await cubit.onMushafPageChanged(0);
    cubit.toggleMode();
    expect((cubit.state as ReaderReady).currentAyahId, 8,
        reason: 'mushaf -> verses must use the page reached, not the route');
  });
}
