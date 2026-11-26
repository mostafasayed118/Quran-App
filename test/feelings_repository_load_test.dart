import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/feelings/data/feelings_repository.dart';
import 'package:quran_yahdi/features/feelings/domain/feeling.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import 'support/test_db.dart';

/// M2 (audit round 2): one ayah must be resolved with a single-ayah lookup,
/// and a feeling's verses must load concurrently.

class _StubUthmani implements UthmaniTextSource {
  int forAyahCalls = 0;
  int inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<Map<int, String>> forSurah(int surahId) async => const {};

  @override
  Future<String?> forAyah(int surahId, int ayah) async {
    forAyahCalls++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    inFlight--;
    return 'نص الآية';
  }
}

class _FakeAyahs extends AyahRepository {
  _FakeAyahs(super.db);

  bool surahAyahsCalled = false;

  @override
  Future<List<Ayah>> surahAyahs(int surahId) {
    surahAyahsCalled = true;
    throw StateError('full-surah read');
  }

  @override
  Future<Surah?> surahById(int surahId) async => null;

  @override
  Future<Ayah?> ayahBySurahAndNumber(int surahId, int numberInSurah) async =>
      Ayah(
        id: 7,
        surahId: surahId,
        numberInSurah: numberInSurah,
        juz: 1,
        page: 1,
        textUthmani: 'glyphs',
        textImlaei: 'imlaei',
        sajda: false,
      );
}

void main() {
  test('a single ayah does not read the whole surah', () async {
    final uthmani = _StubUthmani();
    final ayahs = _FakeAyahs(newTestDb());
    final repo = FeelingsRepository(newTestDb(), uthmani, ayahs);

    final feeling = FeelingsCatalog.byKey(FeelingKey.qalaq)!;
    final view = await repo.load(FeelingKey.qalaq, feeling.verses.first);

    expect(view.fullText, 'نص الآية');
    expect(uthmani.forAyahCalls, 1);
    expect(ayahs.surahAyahsCalled, isFalse);
  });

  test('forFeeling loads its verses concurrently', () async {
    final uthmani = _StubUthmani();
    final ayahs = _FakeAyahs(newTestDb());
    final repo = FeelingsRepository(newTestDb(), uthmani, ayahs);

    final views = await repo.forFeeling(FeelingKey.qalaq);

    expect(views, hasLength(2));
    expect(uthmani.maxInFlight, 2);
  });
}
