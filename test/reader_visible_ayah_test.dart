import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';

import 'support/test_db.dart';

class _RecordingLastRead extends LastReadRepository {
  _RecordingLastRead(super.db);

  final List<int> saves = <int>[];

  @override
  Future<void> saveAyahId(int ayahId) async {
    saves.add(ayahId);
    await super.saveAyahId(ayahId);
  }
}

void main() {
  late AppDatabase db;
  late AyahRepository ayahs;
  late _RecordingLastRead lastRead;

  setUp(() async {
    db = newTestDb();
    ayahs = AyahRepository(db);
    lastRead = _RecordingLastRead(db);
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'الفاتحة',
          nameEn: 'Al-Fatihah',
          revelationType: 'makkah',
          ayahCount: 3,
          pagesStart: 1,
          pagesEnd: 1,
        ));
    await db.batch((b) => b.insertAll(db.ayahs, [
          for (var i = 1; i <= 3; i++)
            AyahsCompanion.insert(
              id: Value(i),
              surahId: 1,
              numberInSurah: i,
              juz: 1,
              page: 1,
              textUthmani: 'آية $i',
              textImlaei: 'آية $i',
            ),
        ]));
  });

  tearDown(() async => db.close());

  test('visible ayah advances last-read once per distinct verse', () async {
    final cubit = ReaderCubit(
      ayahRepository: ayahs,
      lastReadRepository: lastRead,
      surahId: 1,
      initialAyah: 1,
    );
    addTearDown(cubit.close);

    await cubit.start();
    expect(lastRead.saves, [1]);

    await cubit.onVisibleAyah(2);
    await cubit.onVisibleAyah(2);
    await cubit.onVisibleAyah(3);
    await cubit.onVisibleAyah(0);

    expect(lastRead.saves, [1, 2, 3]);
    expect(await lastRead.loadAyahId(), 3);
  });
}
