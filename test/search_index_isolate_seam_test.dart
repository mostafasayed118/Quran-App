import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/search_index.dart';

import 'support/test_db.dart';

/// Imla'i text with diacritics and padded whitespace: the index must store the
/// normalized form, so every assertion below proves normalization actually ran.
const String _seededText = '  بِسْمِ   اللَّهِ  ';
const String _normalizedText = 'بسم الله';

Future<void> _insertAyah(AppDatabase db, int id, String text) =>
    db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: Value(id),
          surahId: 1,
          numberInSurah: id,
          juz: 1,
          page: 1,
          textUthmani: text,
          textImlaei: text,
        ));

void main() {
  test('rebuild uses the injected runner once and writes normalized rows',
      () async {
    final db = newTestDb();
    await _insertAyah(db, 1, _seededText);
    var calls = 0;

    Future<R> run<R>(R Function() computation) async {
      calls++;
      return computation();
    }

    await rebuildQuranSearchIndex(db, run: run);

    expect(calls, 1);
    final row = await db
        .customSelect('SELECT text_norm FROM ayah_search WHERE ayah_id = 1')
        .getSingle();
    expect(row.read<String>('text_norm'), _normalizedText);
  });

  test('the injected runner receives the normalized projection', () async {
    final db = newTestDb();
    await _insertAyah(db, 7, _seededText);
    Object? captured;

    Future<R> run<R>(R Function() computation) async {
      final value = computation();
      captured = value;
      return value;
    }

    await rebuildQuranSearchIndex(db, run: run);

    expect(captured, normalizeSearchEntries([(7, _seededText)]));
    expect(captured, [(7, _normalizedText)]);
    final row = await db
        .customSelect('SELECT text_norm FROM ayah_search WHERE ayah_id = 7')
        .getSingle();
    expect(row.read<String>('text_norm'), _normalizedText);
  });

  test('ensure uses the runner only while the index is stale', () async {
    final db = newTestDb();
    await _insertAyah(db, 1, _seededText);
    var staleCalls = 0;
    var currentCalls = 0;

    Future<R> staleRun<R>(R Function() computation) async {
      staleCalls++;
      return computation();
    }

    Future<R> currentRun<R>(R Function() computation) async {
      currentCalls++;
      return computation();
    }

    await ensureQuranSearchIndex(db, run: staleRun);
    expect(staleCalls, 1);

    await ensureQuranSearchIndex(db, run: currentRun);
    expect(currentCalls, 0);
  });
}
