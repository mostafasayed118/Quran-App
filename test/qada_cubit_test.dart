import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/ramadan/data/qada_source.dart';
import 'package:quran_yahdi/features/ramadan/presentation/qada_cubit.dart';
import 'package:quran_yahdi/features/ramadan/presentation/qada_state.dart';

class _Source implements QadaSource {
  _Source([List<DateTime>? dates]) : dates = dates ?? <DateTime>[];

  List<DateTime> dates;
  bool throwOnSave = false;
  int saves = 0;

  @override
  Future<List<DateTime>> loadMissed() async => dates;

  @override
  Future<void> saveMissed(List<DateTime> next) async {
    if (throwOnSave) throw StateError('save failed');
    saves += 1;
    dates = next;
  }
}

void main() {
  test('start loads the recorded days', () async {
    final source = _Source([DateTime(2027, 3, 1)]);
    final cubit = QadaCubit(source: source);
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as QadaReady;
    expect(ready.dates, [DateTime(2027, 3, 1)]);
  });

  test('add, duplicate add, remove and clear persist the normalized set',
      () async {
    final source = _Source();
    final cubit = QadaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(await cubit.add(DateTime(2027, 3, 2, 21)), isTrue);
    expect(await cubit.add(DateTime(2027, 3, 1)), isTrue);
    expect((cubit.state as QadaReady).dates, [
      DateTime(2027, 3, 1),
      DateTime(2027, 3, 2),
    ]);

    final saves = source.saves;
    expect(await cubit.add(DateTime(2027, 3, 1)), isTrue);
    expect(source.saves, saves, reason: 'a duplicate add writes nothing');

    expect(await cubit.remove(DateTime(2027, 3, 2, 8)), isTrue);
    expect((cubit.state as QadaReady).dates, [DateTime(2027, 3, 1)]);

    expect(await cubit.clear(), isTrue);
    expect((cubit.state as QadaReady).dates, isEmpty);
  });

  test('a failed save reverts the optimistic state', () async {
    final source = _Source();
    final cubit = QadaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();
    source.throwOnSave = true;

    final saved = await cubit.add(DateTime(2027, 3, 1));

    expect(saved, isFalse);
    expect((cubit.state as QadaReady).dates, isEmpty);
  });

  test('mutations before the first load are dropped', () async {
    final cubit = QadaCubit(source: _Source());
    addTearDown(cubit.close);

    expect(await cubit.add(DateTime(2027, 3, 1)), isFalse);
    expect(cubit.state, isA<QadaLoading>());
  });
}
