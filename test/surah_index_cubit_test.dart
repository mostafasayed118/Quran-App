import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_state.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.batch((b) => b.insertAll(db.surahs, [
          SurahsCompanion.insert(
              id: const Value(1),
              nameAr: 'الفاتحة',
              nameEn: 'Al-Fatihah',
              revelationType: 'makkah',
              ayahCount: 7,
              pagesStart: 1,
              pagesEnd: 1),
          SurahsCompanion.insert(
              id: const Value(2),
              nameAr: 'البقرة',
              nameEn: 'Al-Baqarah',
              revelationType: 'madinah',
              ayahCount: 286,
              pagesStart: 2,
              pagesEnd: 49),
        ]));
  });

  test('loading then loaded; setQuery filters client-side', () async {
    final cubit = SurahIndexCubit(SurahRepository(db));
    expect(cubit.state, isA<SurahIndexLoading>());

    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<SurahIndexLoaded>());
    expect((cubit.state as SurahIndexLoaded).surahs.length, 2);

    cubit.setQuery('بقرة');
    await Future<void>.delayed(Duration.zero);
    final loaded = cubit.state as SurahIndexLoaded;
    expect(loaded.surahs.single.nameAr, 'البقرة');
    expect(loaded.query, 'بقرة');

    await cubit.close();
  });

  test('whitespace-only query restores the full list', () async {
    final cubit = SurahIndexCubit(SurahRepository(db));
    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<SurahIndexLoaded>());
    cubit.setQuery('البقرة');
    expect((cubit.state as SurahIndexLoaded).surahs.length, 1);
    cubit.setQuery(' ');
    expect((cubit.state as SurahIndexLoaded).surahs.length, 2);
    await cubit.close();
  });

  test('stream error lands in the existing error state', () async {
    final cubit = SurahIndexCubit(_ThrowingSurahRepository(db));
    expect(cubit.state, isA<SurahIndexLoading>());

    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<SurahIndexError>());
    expect((cubit.state as SurahIndexError).message, isNotEmpty);

    await cubit.close();
  });
}

class _ThrowingSurahRepository extends SurahRepository {
  _ThrowingSurahRepository(super.db);

  @override
  Stream<List<Surah>> watchAll() => Stream.error(StateError('watch failed'));
}
