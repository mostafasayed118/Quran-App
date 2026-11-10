import 'package:drift/drift.dart' show LazyDatabase;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/connection.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_repository.dart';

/// On-device proof that the SHIPPED index answers short tokens.
///
/// The widget test seeds its own four-ayah corpus, so only this leg exercises
/// the real bundled `assets/db/quran.sqlite` through the same open path the app
/// uses (`openAppDatabase` → asset copy → executor → search index).
///
/// The defect: the FTS5 `trigram` tokenizer cannot represent a token shorter
/// than three characters, and it drops such a token from the MATCH expression
/// entirely — so `لا` (2 chars) matched nothing, and a mixed query silently
/// widened into a superset.
///
/// The expected totals are read off the shipped asset; a content bump changes
/// them and this test then fails on purpose, forcing a re-measure.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the shipped index answers two-character tokens', (tester) async {
    final db = AppDatabase(LazyDatabase(openAppDatabase));
    final repo = QuranSearchRepository(db);
    try {
      // Two-character particles: 0 rows before the fix, because the trigram
      // tokenizer dropped them.
      expect((await repo.search('لا')).total, 3093,
          reason: '«لا» must match, not be erased from the query');
      expect((await repo.search('ال')).total, 5155,
          reason: 'the definite article must match');
      expect((await repo.search('يا')).total, 1352,
          reason: 'the vocative particle must match');

      // The three-character path is the control: it always worked.
      expect((await repo.search('الرحمن')).total, 48);

      // A mixed query must be an intersection. Dropping the short token would
      // return every ayah holding «الصلاة» alone (the pre-fix behaviour).
      final longOnly = await repo.search('الصلاة');
      final mixed = await repo.search('من الصلاة');
      expect(mixed.total, greaterThan(0));
      expect(mixed.total, lessThan(longOnly.total),
          reason: 'adding «من» must narrow the result, never widen it');
    } finally {
      await db.close();
    }
  });
}
