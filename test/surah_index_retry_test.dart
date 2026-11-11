import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/surah_source.dart';
import 'package:quran_yahdi/features/quran/domain/surah_summary.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_state.dart';

class _Flaky implements SurahSource {
  int calls = 0;

  @override
  Stream<List<Surah>> watchAll() => const Stream<List<Surah>>.empty();

  @override
  Stream<List<SurahSummary>> watchSummaries() {
    calls += 1;
    if (calls == 1) {
      return Stream<List<SurahSummary>>.error(StateError('first listen fails'));
    }
    return Stream<List<SurahSummary>>.value(const [
      SurahSummary(
        id: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        revelationType: 'makkah',
        ayahCount: 7,
        pagesStart: 1,
        pagesEnd: 1,
      ),
    ]);
  }
}

void main() {
  test('a failed surah index can be retried into a ready state', () async {
    final source = _Flaky();
    final cubit = SurahIndexCubit(source);
    addTearDown(cubit.close);

    await cubit.start();
    await pumpEventQueue();
    expect(cubit.state, isA<SurahIndexFailed>());

    await cubit.reload();
    await pumpEventQueue();
    expect(cubit.state, isA<SurahIndexReady>());
    expect((cubit.state as SurahIndexReady).surahs.single.nameAr, 'الفاتحة');
    expect(source.calls, 2);
  });
}
