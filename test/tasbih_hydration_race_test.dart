import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_state.dart';

import 'support/test_db.dart';

class _GatedTasbihRepository extends TasbihRepository {
  _GatedTasbihRepository(super.db);

  final Completer<void> loadGate = Completer<void>();
  final List<(int, int)> saves = <(int, int)>[];

  @override
  Future<TasbihSnapshot?> load() async {
    await loadGate.future;
    return const TasbihSnapshot(count: 41, target: 99);
  }

  @override
  Future<void> save(int count, int target) async {
    saves.add((count, target));
  }
}

void main() {
  test('a tap during hydration is not overwritten by the stored snapshot',
      () async {
    final repo = _GatedTasbihRepository(newTestDb());
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);

    // Hydration is parked on the gate; the user taps first.
    await cubit.increment();
    expect((cubit.state as TasbihReady).count, 1);

    repo.loadGate.complete();
    await cubit.loaded;

    final ready = cubit.state as TasbihReady;
    expect(ready.count, 1, reason: 'the stored snapshot must not overwrite');
    expect(ready.target, 33);
    expect(repo.saves, <(int, int)>[(1, 33)]);
  });

  test('hydration still applies when the user has not mutated', () async {
    final repo = _GatedTasbihRepository(newTestDb());
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);

    repo.loadGate.complete();
    await cubit.loaded;

    final ready = cubit.state as TasbihReady;
    expect(ready.count, 41);
    expect(ready.target, 99);
  });
}
