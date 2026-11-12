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
  test('a tap during hydration is applied on top of the stored snapshot',
      () async {
    final repo = _GatedTasbihRepository(newTestDb());
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);
    unawaited(cubit.start());

    // Hydration is parked on the gate; the user taps first.
    await cubit.increment();
    expect((cubit.state as TasbihReady).count, 0,
        reason: 'the tap waits for the stored count instead of writing 0+1');

    repo.loadGate.complete();
    await cubit.loaded;

    final ready = cubit.state as TasbihReady;
    expect(ready.count, 42, reason: 'the stored 41 plus the queued tap');
    expect(ready.target, 99);
    expect(repo.saves, <(int, int)>[(42, 99)]);
  });

  test('every queued tap is applied exactly once', () async {
    final repo = _GatedTasbihRepository(newTestDb());
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);
    unawaited(cubit.start());

    await cubit.increment();
    await cubit.increment();

    repo.loadGate.complete();
    await cubit.loaded;

    expect((cubit.state as TasbihReady).count, 43);
    expect(repo.saves, <(int, int)>[(43, 99)]);
  });

  test('hydration still applies when the user has not mutated', () async {
    final repo = _GatedTasbihRepository(newTestDb());
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);
    unawaited(cubit.start());

    repo.loadGate.complete();
    await cubit.loaded;

    final ready = cubit.state as TasbihReady;
    expect(ready.count, 41);
    expect(ready.target, 99);
  });
}
