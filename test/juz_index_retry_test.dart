import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/quran/data/juz_index_source.dart';
import 'package:quran_yahdi/features/quran/domain/juz_summary.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_state.dart';

class _Flaky implements JuzIndexSource {
  final List<StreamController<List<JuzSummary>>> controllers = [];

  @override
  Stream<List<JuzSummary>> watchJuz() {
    final controller = StreamController<List<JuzSummary>>.broadcast();
    controllers.add(controller);
    return controller.stream;
  }
}

const _juz1 = JuzSummary(
  juz: 1,
  firstPage: 1,
  surahId: 1,
  numberInSurah: 1,
  surahName: 'الفاتحة',
);
const _juz2 = JuzSummary(
  juz: 2,
  firstPage: 22,
  surahId: 2,
  numberInSurah: 142,
  surahName: 'البقرة',
);

void main() {
  test('a retry cancels the previous juz subscription', () async {
    final source = _Flaky();
    final cubit = JuzIndexCubit(source: source);
    addTearDown(() async {
      await cubit.close();
      for (final controller in source.controllers) {
        await controller.close();
      }
    });

    await cubit.start();
    source.controllers[0].add(const [_juz1]);
    await pumpEventQueue();
    expect((cubit.state as JuzIndexReady).juz.single.juz, 1);

    await cubit.start();
    source.controllers[0].add(const [_juz2]);
    await pumpEventQueue();
    expect((cubit.state as JuzIndexReady).juz.single.juz, 1,
        reason: 'the orphaned stream must not emit into the cubit');

    source.controllers[1].add(const [_juz2]);
    await pumpEventQueue();
    expect((cubit.state as JuzIndexReady).juz.single.juz, 2);
    expect(source.controllers, hasLength(2));
  });
}
