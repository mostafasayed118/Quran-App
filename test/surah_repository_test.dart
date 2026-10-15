import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';

void main() {
  late AppDatabase db;
  late SurahRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    await db.batch((b) => b.insertAll(db.surahs, [
      SurahsCompanion.insert(
          id: const Value(1), nameAr: 'الفاتحة', nameEn: 'Al-Fatihah',
          revelationType: 'makkah', ayahCount: 7, pagesStart: 1, pagesEnd: 1),
      SurahsCompanion.insert(
          id: const Value(2), nameAr: 'البقرة', nameEn: 'Al-Baqarah',
          revelationType: 'madinah', ayahCount: 286, pagesStart: 2, pagesEnd: 49),
      SurahsCompanion.insert(
          id: const Value(3), nameAr: 'آل عمران', nameEn: 'Aal-i-Imraan',
          revelationType: 'madinah', ayahCount: 200, pagesStart: 50, pagesEnd: 76),
    ]));
    repo = SurahRepository(db);
  });

  tearDown(() => db.close());

  test('watchAll returns surahs ordered by id', () async {
    final list = await repo.watchAll().first;
    expect(list.map((s) => s.id).toList(), [1, 2, 3]);
  });
}
