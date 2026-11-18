import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/search_index.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_repository.dart';

import 'support/test_db.dart';

/// RED for the legacy-substring search IN-variable risk (audit Task A).
///
/// The legacy path builds one `LIKE ?` per query token. With no cap, a long
/// query builds >999 host variables and fails on Android's SQLite. The
/// interceptor emulates that 999 ceiling on this host's larger SQLite.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = newLimitedVarDb(limit: 999);
    await db
        .into(db.surahs)
        .insert(
          SurahsCompanion.insert(
            id: const Value(1),
            nameAr: 'الفاتحة',
            nameEn: 'Al-Fatihah',
            revelationType: 'makkah',
            ayahCount: 2,
            pagesStart: 1,
            pagesEnd: 1,
          ),
        );
    final texts = <(int, int, int, String)>[
      (1, 1, 1, 'بسم الله الرحمن الرحيم'),
      (2, 1, 2, 'الذين يؤمنون بالغيب ويقيمون الصلاة'),
    ];
    for (final (id, surahId, number, text) in texts) {
      await db
          .into(db.ayahs)
          .insert(
            AyahsCompanion.insert(
              id: Value(id),
              surahId: surahId,
              numberInSurah: number,
              juz: 1,
              page: 1,
              textUthmani: text,
              textImlaei: text,
            ),
          );
    }
    await rebuildQuranSearchIndex(db);
  });

  test('a 1500-token legacy query stays under the variable ceiling', () async {
    final repo = QuranSearchRepository(db);
    // 'من' is a 2-char token (< trigram min) so the legacy path is forced.
    // 1500 repeats on the current code build 1500 LIKE ? variables -> the
    // interceptor throws "too many SQL variables". After the token cap the
    // statement stays bounded and returns the same hits as a single 'من'.
    final query = List<String>.filled(1500, 'من').join(' ');

    final page = await repo.search(query);

    final control = await repo.search('من');
    expect(page.hits.map((h) => h.ayahId), control.hits.map((h) => h.ayahId));
    expect(page.total, control.total);
  });
}
