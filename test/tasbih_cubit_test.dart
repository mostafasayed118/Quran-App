import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_state.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late TasbihRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = TasbihRepository(db);
  });

  Future<TasbihCubit> build() async {
    final cubit = TasbihCubit(repo: repo);
    await cubit.loaded;
    return cubit;
  }

  test('increments count to 3', () async {
    final cubit = await build();
    for (var i = 0; i < 3; i++) {
      await cubit.increment();
    }
    expect((cubit.state as TasbihReady).count, 3);
    await cubit.close();
  });

  test('reaching the target sets a one-shot flag cleared by the next increment',
      () async {
    final cubit = await build();
    await cubit.selectTarget(33);
    for (var i = 0; i < 32; i++) {
      await cubit.increment();
    }
    expect((cubit.state as TasbihReady).reachedTarget, isFalse);
    await cubit.increment();
    expect((cubit.state as TasbihReady).reachedTarget, isTrue);
    await cubit.increment();
    expect((cubit.state as TasbihReady).reachedTarget, isFalse);
    await cubit.close();
  });

  test('reset zeroes the count; selectTarget zeroes and changes target',
      () async {
    final cubit = await build();
    await cubit.selectTarget(100);
    for (var i = 0; i < 5; i++) {
      await cubit.increment();
    }
    await cubit.reset();
    final ready = cubit.state as TasbihReady;
    expect(ready.count, 0);
    expect(ready.target, 100);

    await cubit.selectTarget(500);
    expect((cubit.state as TasbihReady).count, 0);
    expect((cubit.state as TasbihReady).target, 500);
    await cubit.close();
  });

  test('second life loads the persisted count', () async {
    final first = await build();
    for (var i = 0; i < 7; i++) {
      await first.increment();
    }
    await first.close();

    final second = await build();
    expect((second.state as TasbihReady).count, 7);
    await second.close();
  });
}
