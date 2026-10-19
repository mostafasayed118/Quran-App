import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('v1 schema creates all 8 tables and surah rows roundtrip', () async {
    expect(db.allTables.length, 9); // w2a: + reciters (PM grant)

    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
            id: const Value(1),
            nameAr: 'الفاتحة',
            nameEn: 'Al-Fatihah',
            revelationType: 'المكية',
            ayahCount: 7,
            pagesStart: 1,
            pagesEnd: 1,
          ),
        );

    final fetched = await db.select(db.surahs).get();
    expect(fetched.single.nameAr, 'الفاتحة');
    expect(fetched.single.pagesEnd, 1);
  });

  test('ayahs table roundtrips uthmani + imlaei text', () async {
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(1),
            surahId: 1,
            numberInSurah: 1,
            juz: 1,
            page: 1,
            textUthmani: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textImlaei: 'بسم الله الرحمن الرحيم',
          ),
        );

    final fetched = await db.select(db.ayahs).get();
    expect(fetched.single.textImlaei, 'بسم الله الرحمن الرحيم');
    expect(fetched.single.sajda, false);
  });

  test('hot-path indexes exist after open', () async {
    // Force the first open: the beforeOpen hook must have run by the time
    // this query executes.
    await db.customSelect('SELECT 1').get();
    final names = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .map((row) => row.read<String>('name'))
        .get();
    expect(
        names,
        containsAll(<String>[
          'idx_ayahs_surah',
          'idx_bookmarks_ayah',
          'idx_downloads_lookup',
        ]));
  });

  test('v2 adds reciters table; companion roundtrips a row', () async {
    final db2 = AppDatabase.test(NativeDatabase.memory());
    await db2.into(db2.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'https://server11.mp3quran.net/basit/',
            surahList: '1,2,3',
            surahTotal: 114,
          ),
        );
    final row = await db2.select(db2.reciters).getSingle();
    expect(row.id, '51-53');
    expect(row.surahTotal, 114);
    await db2.close();
  });
}
