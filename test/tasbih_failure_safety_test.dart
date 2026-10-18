import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_state.dart';

void main() {
  test('a broken snapshot load neither throws nor hangs the cubit', () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    final repo = TasbihRepository(db);
    await db.close();

    final cubit = TasbihCubit(repo: repo);
    await cubit.loaded.timeout(const Duration(seconds: 5));

    final ready = cubit.state as TasbihReady;
    expect(ready.count, 0);
    expect(ready.target, 33);
    await cubit.close();
  });

  test('a failing save never throws and the counter keeps working', () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    final repo = TasbihRepository(db);
    await db.close();

    final cubit = TasbihCubit(repo: repo);
    await cubit.loaded.timeout(const Duration(seconds: 5));

    await cubit.increment();
    expect((cubit.state as TasbihReady).count, 1);
    await cubit.selectTarget(99);
    expect((cubit.state as TasbihReady).target, 99);
    await cubit.reset();
    expect((cubit.state as TasbihReady).count, 0);
    await cubit.close();
  });
}
