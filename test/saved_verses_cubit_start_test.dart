import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/feelings/data/feelings_repository.dart';
import 'package:quran_yahdi/features/feelings/domain/saved_feeling_verse.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_state.dart';
import 'package:quran_yahdi/features/feelings/presentation/saved_verses_cubit.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import 'support/test_db.dart';

/// M3 (audit round 2): constructing the cubit must not touch the repository;
/// the route's `start()` owns the subscription (RouteCubitScope contract).

class _EmptyUthmani implements UthmaniTextSource {
  @override
  Future<Map<int, String>> forSurah(int surahId) async => const {};

  @override
  Future<String?> forAyah(int surahId, int ayah) async => null;
}

class _StreamRepo extends FeelingsRepository {
  _StreamRepo(AppDatabase db) : super(db, _EmptyUthmani(), AyahRepository(db));

  int watchCalls = 0;
  final controller = StreamController<List<SavedFeelingVerse>>.broadcast();

  @override
  Stream<List<SavedFeelingVerse>> watchSaved() {
    watchCalls++;
    return controller.stream;
  }
}

void main() {
  test('constructing the cubit performs no I/O', () async {
    final repo = _StreamRepo(newTestDb());
    final cubit = SavedVersesCubit(repo);
    addTearDown(cubit.close);

    expect(repo.watchCalls, 0);
    expect(cubit.state, isA<SavedVersesLoading>());
  });

  test('start subscribes once and emits the saved list', () async {
    final repo = _StreamRepo(newTestDb());
    final cubit = SavedVersesCubit(repo);
    addTearDown(cubit.close);

    await cubit.start();
    await cubit.start();
    expect(repo.watchCalls, 1);

    repo.controller.add(const <SavedFeelingVerse>[]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<SavedVersesReady>());
  });
}
