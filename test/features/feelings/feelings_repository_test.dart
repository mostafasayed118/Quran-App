import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/feelings/data/feelings_repository.dart';
import 'package:quran_yahdi/features/feelings/domain/feeling.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import '../../support/test_db.dart';

class _EmptyUthmani implements UthmaniTextSource {
  @override
  Future<Map<int, String>> forSurah(int surahId) async => {};

  @override
  Future<String?> forAyah(int surahId, int ayah) async =>
      (await forSurah(surahId))[ayah];
}

void main() {
  test('saved verses: save, duplicate prevention, unsave and delete', () async {
    final db = newTestDb();
    final repo = FeelingsRepository(db, _EmptyUthmani(), AyahRepository(db));

    await repo.save(42, FeelingKey.qalaq);
    await repo.save(42, FeelingKey.huzn); // duplicate must be ignored
    expect(await repo.savedCount(), 1);
    expect(await repo.isSaved(42), isTrue);

    await repo.unsave(42);
    expect(await repo.savedCount(), 0);
    expect(await repo.isSaved(42), isFalse);

    await repo.save(7, FeelingKey.amal);
    final rows = await db.select(db.feelingSavedVerses).get();
    await repo.delete(rows.single.id);
    expect(await repo.savedCount(), 0);
  });
}
