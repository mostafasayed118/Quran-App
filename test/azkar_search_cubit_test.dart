import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_state.dart';

Map<String, dynamic> _root() => {
      'collections': [
        {
          'id': 'c1',
          'nameAr': 'أذكار الصباح',
          'nameEn': 'Morning',
          'items': [
            {'text': 'اللَّهُمَّ بِكَ أَصْبَحْنَا', 'count': 1},
            {'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 'count': 3},
          ],
        },
        {
          'id': 'c2',
          'nameAr': 'أذكار النوم',
          'nameEn': 'Sleep',
          'items': [
            {'text': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', 'count': 1},
          ],
        },
      ],
    };

AzkarCubit _cubit() =>
    AzkarCubit(repository: AzkarRepository(loader: () async => _root()));

void main() {
  test('searching emits hits; clearing the query restores the list', () async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setSearchQuery('النوم');
    await pumpEventQueue();

    final searching = cubit.state as AzkarBrowsing;
    expect(searching.query, 'النوم');
    expect(searching.searchResults, hasLength(1));
    expect(searching.searchResults.single.collection.id, 'c2');
    expect(searching.searchHasMore, isFalse);
    expect(searching.collections, hasLength(2));

    cubit.setSearchQuery('');
    final cleared = cubit.state as AzkarBrowsing;
    expect(cleared.query, isEmpty);
    expect(cleared.searchResults, isEmpty);
    expect(cleared.collections, hasLength(2));
  });

  test('an unmatched query keeps an empty result set', () async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setSearchQuery('لا يوجد');
    await pumpEventQueue();

    final state = cubit.state as AzkarBrowsing;
    expect(state.query, 'لا يوجد');
    expect(state.searchResults, isEmpty);
  });

  test('opening a collection mid-search discards the stale results', () async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setSearchQuery('النوم');
    final browsing = cubit.state as AzkarBrowsing;
    cubit.open(browsing.collections.first);
    await pumpEventQueue();

    expect(cubit.state, isA<AzkarReciting>());
  });

  test('back from the reciting view restores the plain list', () async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await cubit.load();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.back();
    await pumpEventQueue();

    final state = cubit.state as AzkarBrowsing;
    expect(state.query, isEmpty);
    expect(state.searchResults, isEmpty);
    expect(state.collections, hasLength(2));
  });
}
