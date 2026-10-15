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
    expect(db.allTables.length, 8);

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
}
