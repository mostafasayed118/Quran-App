import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_state.dart';

import 'support/test_db.dart';

const String _today = '2026-11-02';
final DateTime _now = DateTime(2026, 11, 2, 9);

Map<String, dynamic> _catalog() => {
      'collections': [
        {
          'id': 'morning',
          'nameAr': 'أذكار الصباح',
          'nameEn': 'Morning',
          'items': [
            {'text': 'ذِكْرٌ أَوَّل', 'count': 3},
            {'text': 'ذِكْرٌ ثَانٍ', 'count': 2},
          ],
        },
        {
          'id': 'evening',
          'nameAr': 'أذكار المساء',
          'nameEn': 'Evening',
          'items': [
            {'text': 'ذِكْرٌ وَاحِد', 'count': 1},
          ],
        },
      ],
    };

/// A source whose first read can be held open, so the cubit can be driven
/// while hydration is still pending.
class _GatedSource implements AzkarSavedStateSource {
  _GatedSource(this.stored);

  AzkarSavedState stored;
  Completer<void>? gate;

  @override
  Future<AzkarSavedState> load() async {
    final pending = gate;
    if (pending != null) await pending.future;
    return stored;
  }

  @override
  Future<void> saveRemaining(
    String collectionId,
    List<int> remaining,
    String day,
  ) async {
    stored = AzkarSavedState(
      day: day,
      remaining: {...stored.remaining, collectionId: remaining},
      favorites: stored.favorites,
    );
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) async {
    stored = AzkarSavedState(
      day: stored.day,
      remaining: stored.remaining,
      favorites: favorites,
    );
  }
}

void main() {
  test('opening a collection before hydration resumes the saved counters',
      () async {
    final gate = Completer<void>();
    final source = _GatedSource(const AzkarSavedState(
      day: _today,
      remaining: {
        'morning': [0, 1],
      },
    ))
      ..gate = gate;

    final cubit = AzkarCubit(
      repository: AzkarRepository(loader: () async => _catalog()),
      savedState: source,
      clock: () => _now,
    );
    addTearDown(cubit.close);

    final loading = cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AzkarBrowsing>());

    final collection = (cubit.state as AzkarBrowsing).collections.first;
    cubit.open(collection);
    gate.complete();
    await loading;
    await Future<void>.delayed(Duration.zero);

    expect(
      (cubit.state as AzkarReciting).remaining,
      [0, 1],
      reason: 'the open must wait for the stored counters, not start at full',
    );
  });

  test('two collection saves racing keep both collections', () async {
    final db = newTestDb();
    final repo = AzkarSavedStateRepository(db);

    await Future.wait([
      repo.saveRemaining('morning', const [1, 1], _today),
      repo.saveRemaining('evening', const [0], _today),
    ]);

    final loaded = await AzkarSavedStateRepository(db).load();
    expect(loaded.remaining['morning'], [1, 1]);
    expect(loaded.remaining['evening'], [0]);
  });

  test('a save racing the first load keeps the other collection', () async {
    final db = newTestDb();
    final repo = AzkarSavedStateRepository(db);
    await repo.saveRemaining('morning', const [2, 2], _today);

    final reads = <Future<void>>[
      repo.saveRemaining('evening', const [1], _today),
      repo.saveRemaining('morning', const [1, 2], _today),
    ];
    await Future.wait(reads);

    final loaded = await AzkarSavedStateRepository(db).load();
    expect(loaded.remaining['morning'], [1, 2]);
    expect(loaded.remaining['evening'], [1]);
  });
}
