import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/translation_search_source.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_state.dart';

class _Flaky implements TranslationSearchSource {
  int calls = 0;

  @override
  Future<List<String>> installedTranslationIds() async {
    calls += 1;
    if (calls == 1) throw StateError('first load fails');
    return const <String>[];
  }

  @override
  Future<Map<int, String>> translationIndex(String packId) async =>
      const <int, String>{};
}

void main() {
  test('the translation search retry actually reloads', () async {
    final source = _Flaky();
    final cubit = TranslationSearchCubit(
      source: source,
      surahName: (_) async => '',
      debounce: Duration.zero,
    );
    addTearDown(cubit.close);

    await cubit.start();
    expect(cubit.state, isA<TranslationSearchFailed>());

    await cubit.start();
    expect(cubit.state, isA<TranslationSearchReady>());
    expect((cubit.state as TranslationSearchReady).hasPacks, isFalse);
    expect(source.calls, 2);
  });
}
