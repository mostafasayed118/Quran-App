import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/surah_source.dart';
import 'package:quran_yahdi/features/quran/domain/surah_summary.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_state.dart';

const _fatihah = SurahSummary(
  id: 1,
  nameAr: 'الفاتحة',
  nameEn: 'Al-Fatihah',
  revelationType: 'makkah',
  ayahCount: 7,
  pagesStart: 1,
  pagesEnd: 1,
);

const _baqarah = SurahSummary(
  id: 2,
  nameAr: 'البقرة',
  nameEn: 'Al-Baqarah',
  revelationType: 'madinah',
  ayahCount: 286,
  pagesStart: 2,
  pagesEnd: 49,
);

class _FakeSurahSource implements SurahSource {
  @override
  Stream<List<Surah>> watchAll() => const Stream<List<Surah>>.empty();

  @override
  Stream<List<SurahSummary>> watchSummaries() =>
      Stream<List<SurahSummary>>.value(const [_fatihah, _baqarah]);
}

Future<SurahIndexCubit> _readyCubit() async {
  final cubit = SurahIndexCubit(_FakeSurahSource());
  await cubit.start();
  await Future<void>.delayed(Duration.zero);
  expect(cubit.state, isA<SurahIndexReady>());
  return cubit;
}

void main() {
  test('ta-marbuta-insensitive query matches the surah name', () async {
    final cubit = await _readyCubit();

    cubit.setQuery('الفاتحه');

    final ready = cubit.state as SurahIndexReady;
    expect(ready.surahs.single.nameAr, 'الفاتحة');
    await cubit.close();
  });

  test('arabic-indic digits match the surah id', () async {
    final cubit = await _readyCubit();

    cubit.setQuery('٢');

    final ready = cubit.state as SurahIndexReady;
    expect(ready.surahs.single.id, 2);
    await cubit.close();
  });

  test('a non-matching query yields an empty list', () async {
    final cubit = await _readyCubit();

    cubit.setQuery('ززز');

    expect((cubit.state as SurahIndexReady).surahs, isEmpty);
    await cubit.close();
  });
}
