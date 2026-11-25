// Issue 1 (audit Top 5): the Q46 saved list must resolve every reference in
// ONE batch lookup per emission, not one DB query per visible row per rebuild.
// The cubit does the work; the widget renders the already-resolved label.
import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/ayah_batch_lookup.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/features/feelings/data/feelings_repository.dart';
import 'package:quran_yahdi/features/feelings/domain/feeling.dart';
import 'package:quran_yahdi/features/feelings/domain/saved_feeling_verse.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_cubit.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_state.dart';
import 'package:quran_yahdi/features/feelings/presentation/saved_verses_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import '../../support/host.dart';
import '../../support/test_db.dart';

class _EmptyUthmani implements UthmaniTextSource {
  @override
  Future<Map<int, String>> forSurah(int surahId) async => {};
}

/// A repo whose saved-list stream is controlled by the test.
class _StreamRepo extends FeelingsRepository {
  _StreamRepo(AppDatabase db, this._controller)
    : super(db, _EmptyUthmani(), AyahRepository(db));

  final StreamController<List<SavedFeelingVerse>> _controller;

  @override
  Stream<List<SavedFeelingVerse>> watchSaved() => _controller.stream;
}

/// Any per-row fallback would hit this port; count it and return null.
class _CountingLookup implements AyahLookup {
  int byIdCalls = 0;

  @override
  Future<Ayah?> ayahById(int ayahId) async {
    byIdCalls++;
    return null;
  }

  @override
  Future<Surah?> surahById(int surahId) =>
      throw StateError('unexpected per-row surah lookup');

  @override
  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah) =>
      throw StateError('unexpected per-row range lookup');
}

/// The batch seam: one invocation for the whole emission, missing ids skipped.
class _CountingBatch implements AyahBatchLookup {
  static const resolved = <int, (int, int)>{
    10: (13, 28),
    20: (65, 2),
    30: (2, 1),
  };

  int calls = 0;
  List<int>? lastIds;

  @override
  Future<List<Ayah>> ayahsByIds(List<int> ids) async {
    calls++;
    lastIds = List<int>.from(ids);
    return [
      for (final id in ids)
        if (resolved.containsKey(id))
          Ayah(
            id: id,
            surahId: resolved[id]!.$1,
            numberInSurah: resolved[id]!.$2,
            juz: 1,
            page: 1,
            textUthmani: 'text-$id',
            textImlaei: 'text-$id',
            sajda: false,
          ),
    ];
  }
}

SavedFeelingVerse _saved(int id, int ayahId) => SavedFeelingVerse(
  id: id,
  ayahId: ayahId,
  feeling: FeelingKey.qalaq,
  createdAt: DateTime(2026, 11, 25, id),
);

class _SelectCounter extends QueryInterceptor {
  int ayahSelects = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.toLowerCase().contains('ayahs')) ayahSelects++;
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  test(
    'one batch lookup per emission, zero per-row lookups, refs resolved',
    () async {
      final db = newTestDb();
      final controller = StreamController<List<SavedFeelingVerse>>();
      addTearDown(controller.close);
      final repo = _StreamRepo(db, controller);
      final lookup = _CountingLookup();
      final batch = _CountingBatch();
      final cubit = SavedVersesCubit(repo, lookup: lookup, batch: batch);
      addTearDown(cubit.close);

      // Deliberately unordered ayah ids, plus one id absent from the catalog.
      controller.add([
        _saved(1, 30),
        _saved(2, 10),
        _saved(3, 999),
        _saved(4, 20),
      ]);
      final ready = (await cubit.stream.firstWhere(
        (s) => s is SavedVersesReady,
      )) as SavedVersesReady;

      expect(batch.calls, 1, reason: 'one batch invocation for the emission');
      expect(batch.lastIds, [30, 10, 999, 20], reason: 'saved order preserved');
      expect(lookup.byIdCalls, 0, reason: 'no per-row ayahRefById fallback');

      expect(ready.verses.map((v) => v.id).toList(), [1, 2, 3, 4]);
      expect(ready.refs[10]?.surahId, 13);
      expect(ready.refs[10]?.numberInSurah, 28);
      expect(ready.refs[20]?.surahId, 65);
      expect(ready.refs[30]?.numberInSurah, 1);
      expect(
        ready.refs.containsKey(999),
        isFalse,
        reason: 'missing id skipped',
      );
    },
  );

  test('a second emission batches again, never once per row', () async {
    final db = newTestDb();
    final controller = StreamController<List<SavedFeelingVerse>>();
    addTearDown(controller.close);
    final repo = _StreamRepo(db, controller);
    final lookup = _CountingLookup();
    final batch = _CountingBatch();
    final cubit = SavedVersesCubit(repo, lookup: lookup, batch: batch);
    addTearDown(cubit.close);

    controller.add([_saved(1, 10)]);
    await cubit.stream.firstWhere((s) => s is SavedVersesReady);
    controller.add([_saved(1, 10), _saved(2, 20)]);
    await cubit.stream.firstWhere(
      (s) => s is SavedVersesReady && s.verses.length == 2,
    );

    expect(batch.calls, 2, reason: 'one per emission, not one per row');
    expect(lookup.byIdCalls, 0);
  });

  testWidgets('Q46 renders resolved labels without per-row FutureBuilders', (
    tester,
  ) async {
    final db = newTestDb();
    final controller = StreamController<List<SavedFeelingVerse>>();
    addTearDown(controller.close);
    final repo = _StreamRepo(db, controller);
    final lookup = _CountingLookup();
    final batch = _CountingBatch();
    final cubit = SavedVersesCubit(repo, lookup: lookup, batch: batch);
    addTearDown(cubit.close);

    controller.add([_saved(1, 10), _saved(2, 999)]);
    await cubit.stream.firstWhere((s) => s is SavedVersesReady);

    await pumpAppHost(
      tester,
      home: BlocProvider<SavedVersesCubit>.value(
        value: cubit,
        child: const SavedVersesScreen(),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate((w) => w is FutureBuilder),
      findsNothing,
      reason: 'no per-row future may be created from build()',
    );
    expect(find.text('قلق · 13:28'), findsOneWidget);
    expect(find.text('قلق'), findsOneWidget, reason: 'missing-id fallback');
    expect(lookup.byIdCalls, 0);
    expect(batch.calls, 1);
  });

  test(
    'ayahsByIds performs one underlying database query for the set',
    () async {
      final counter = _SelectCounter();
      final db = AppDatabase.test(
        NativeDatabase.memory().interceptWith(counter),
      );
      addTearDown(db.close);

      for (final id in [10, 20, 30]) {
        await db
            .into(db.ayahs)
            .insert(
              Ayah(
                id: id,
                surahId: id,
                numberInSurah: 1,
                juz: 1,
                page: 1,
                textUthmani: 'text-$id',
                textImlaei: 'text-$id',
                sajda: false,
              ),
            );
      }
      // Inserts/seed reads are not selects; reset before measuring the batch.
      counter.ayahSelects = 0;

      final rows = await AyahRepository(db).ayahsByIds([10, 20, 30, 999]);

      expect(
        counter.ayahSelects,
        1,
        reason: 'one SELECT for the whole IN list',
      );
      expect(rows.map((r) => r.id).toList(), [10, 20, 30]);
    },
  );
}
