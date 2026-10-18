import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_cubit.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_state.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

class _CountingAyahs extends AyahRepository {
  _CountingAyahs(super.db);

  int rangeCalls = 0;
  int surahCalls = 0;

  @override
  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah) {
    rangeCalls++;
    return super.ayahsForRange(surahId, fromAyah, toAyah);
  }

  @override
  Future<Surah?> surahById(int surahId) {
    surahCalls++;
    return super.surahById(surahId);
  }
}

void main() {
  test('ruqyah ranges resolve once; re-visiting the tab does not re-query',
      () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(112),
          nameAr: 'الإخلاص',
          nameEn: 'Al-Ikhlas',
          revelationType: 'Meccan',
          ayahCount: 4,
          pagesStart: 604,
          pagesEnd: 604,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(6220),
          surahId: 112,
          numberInSurah: 1,
          juz: 30,
          page: 604,
          textUthmani: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
          textImlaei: 'قل هو الله أحد',
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(6221),
          surahId: 112,
          numberInSurah: 2,
          juz: 30,
          page: 604,
          textUthmani: 'اللَّهُ الصَّمَدُ',
          textImlaei: 'الله الصمد',
        ));

    final ayahs = _CountingAyahs(db);
    final cubit = DuasCubit(
      duas: DuaRepository(
          loader: () async => [
                {
                  'id': 'a1',
                  'categoryAr': 'المنزل',
                  'categoryEn': 'Home',
                  'text': 'بِسْمِ اللَّهِ وَلَجْنَا',
                },
              ]),
      ruqyah: RuqyahRepository(
          loader: () async => [
                {
                  'id': 'r1',
                  'kind': 'dhikr',
                  'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
                  'count': 3,
                },
                {
                  'id': 'r2',
                  'kind': 'quran',
                  'surahId': 112,
                  'fromAyah': 1,
                  'toAyah': 2,
                },
              ]),
      ayahs: ayahs,
    );
    addTearDown(cubit.close);
    await cubit.showDuas();

    await cubit.showRuqyah();
    expect(ayahs.rangeCalls, 1);
    expect(ayahs.surahCalls, 1);
    final first = (cubit.state as RuqyahInView).entries;

    await cubit.showDuas();
    await cubit.showRuqyah();

    expect(ayahs.rangeCalls, 1,
        reason: 'second visit must reuse the resolved rows');
    expect(ayahs.surahCalls, 1,
        reason: 'second visit must reuse the resolved surah names');
    final second = (cubit.state as RuqyahInView).entries;
    expect(second, hasLength(first.length));
    expect(second.first.displayText, first.first.displayText);
    expect(second.last.displayText, first.last.displayText);
    expect(second.last.citation, first.last.citation);
  });
}
