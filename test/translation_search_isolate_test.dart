import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/library/data/translation_search_source.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_state.dart';

class _Source implements TranslationSearchSource {
  @override
  Future<List<String>> installedTranslationIds() async => ['en1'];

  @override
  Future<Map<int, String>> translationIndex(String packId) async => {
        1001: 'In the name of Allah, the Entirely Merciful',
      };
}

void main() {
  test('the pack preparation runs through the injected runner', () async {
    var runs = 0;
    final cubit = TranslationSearchCubit(
      source: _Source(),
      surahName: (id) async => 'سورة $id',
      debounce: Duration.zero,
      prepare: <R>(R Function() computation) async {
        runs++;
        return computation();
      },
    );
    addTearDown(cubit.close);

    await cubit.start();

    expect(runs, 1,
        reason: 'every installed pack is normalized in one off-isolate pass');
    expect((cubit.state as TranslationSearchReady).hasPacks, isTrue);

    cubit.setQuery('merciful');
    await pumpEventQueue();
    expect((cubit.state as TranslationSearchReady).total, 1);
  });
}
