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
          ],
        },
      ],
    };

class _FailingSearchRepository extends AzkarRepository {
  _FailingSearchRepository() : super(loader: () async => _root());

  @override
  Future<AzkarSearchResults> search(String query,
          {int limit = AzkarRepository.searchLimit}) =>
      Future<AzkarSearchResults>.error(StateError('search down'));
}

void main() {
  test('a failed search keeps the typed query in the browsing state', () async {
    final cubit = AzkarCubit(repository: _FailingSearchRepository());
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setSearchQuery('الصباح');
    await pumpEventQueue();

    final state = cubit.state as AzkarBrowsing;
    expect(state.query, 'الصباح');
    expect(state.searchResults, isEmpty);
    expect(state.collections, hasLength(1));
  });
}
