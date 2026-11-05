import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/library/data/translation_search_source.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_state.dart';

class _Source implements TranslationSearchSource {
  _Source(this.ids, this.indexes, {this.throwOnLoad = false});

  final List<String> ids;
  final Map<String, Map<int, String>> indexes;
  final bool throwOnLoad;

  @override
  Future<List<String>> installedTranslationIds() async {
    if (throwOnLoad) throw StateError('load failed');
    return ids;
  }

  @override
  Future<Map<int, String>> translationIndex(String packId) async =>
      indexes[packId] ?? const <int, String>{};
}

TranslationSearchCubit _cubit(_Source source) => TranslationSearchCubit(
      source: source,
      surahName: (id) async => 'سورة $id',
      debounce: Duration.zero,
    );

void main() {
  test('loads the installed indexes and searches them case-insensitively',
      () async {
    final source = _Source(
      ['en1'],
      {
        'en1': {
          1001: 'In the name of Allah, the Entirely Merciful',
          2001: 'Praise be to Allah',
        },
      },
    );
    final cubit = _cubit(source);
    addTearDown(cubit.close);

    await cubit.start();
    expect((cubit.state as TranslationSearchReady).hasPacks, isTrue);

    cubit.setQuery('merciful');
    await pumpEventQueue();

    final ready = cubit.state as TranslationSearchReady;
    expect(ready.query, 'merciful');
    expect(ready.total, 1);
    expect(ready.hits, hasLength(1));
    expect(ready.hits.single.surahId, 1);
    expect(ready.hits.single.ayah, 1);
    expect(ready.hits.single.surahName, 'سورة 1');
    expect(ready.hits.single.text, contains('Merciful'));
  });

  test('Arabic queries ignore diacritics and letter variants', () async {
    final source = _Source(
      ['ar1'],
      {
        'ar1': {1001: 'الرَّحْمَٰنِ الرَّحِيمِ'},
      },
    );
    final cubit = _cubit(source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.setQuery('الرحمن');
    await pumpEventQueue();

    final ready = cubit.state as TranslationSearchReady;
    expect(ready.hits, hasLength(1));
    expect(ready.hits.single.ayah, 1);
  });

  test('caps the rendered hits while keeping the real total', () async {
    final source = _Source(
      ['en1'],
      {
        'en1': {
          for (var i = 0; i < 150; i++) 1000 + i: 'test entry $i',
        },
      },
    );
    final cubit = _cubit(source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.setQuery('test');
    await pumpEventQueue();

    final ready = cubit.state as TranslationSearchReady;
    expect(ready.total, 150);
    expect(ready.hits, hasLength(TranslationSearchCubit.maxHits));
  });

  test('an empty query clears the results', () async {
    final source = _Source(
      ['en1'],
      {
        'en1': {1001: 'mercy'},
      },
    );
    final cubit = _cubit(source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.setQuery('mercy');
    await pumpEventQueue();
    cubit.setQuery('');
    await pumpEventQueue();

    final ready = cubit.state as TranslationSearchReady;
    expect(ready.query, isEmpty);
    expect(ready.hits, isEmpty);
  });

  test('no installed translations reports hasPacks false', () async {
    final cubit = _cubit(_Source([], {}));
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as TranslationSearchReady;
    expect(ready.hasPacks, isFalse);
    expect(ready.hits, isEmpty);
  });

  test('a load failure lands in the failed state', () async {
    final cubit = _cubit(_Source([], {}, throwOnLoad: true));
    addTearDown(cubit.close);

    await cubit.start();

    expect(cubit.state, isA<TranslationSearchFailed>());
  });
}
