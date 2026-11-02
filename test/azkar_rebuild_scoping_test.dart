import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_state.dart';

const _collection = AzkarCollection(
  id: 'morning',
  nameAr: 'أذكار الصباح',
  nameEn: 'Morning',
  items: [
    AzkarItem(text: 'ذِكْرٌ', count: 3),
  ],
);

const _otherCollection = AzkarCollection(
  id: 'evening',
  nameAr: 'أذكار المساء',
  nameEn: 'Evening',
  items: [
    AzkarItem(text: 'ذِكْرٌ', count: 1),
  ],
);

AzkarReciting _reciting(
  List<int> remaining, {
  AzkarCollection collection = _collection,
}) =>
    AzkarState.reciting(collection: collection, remaining: remaining)
        as AzkarReciting;

AzkarBrowsing _browsing({
  List<AzkarCollection> collections = const [_collection],
  Set<String> favorites = const {},
  String query = '',
}) =>
    AzkarState.browsing(
      collections: collections,
      favorites: favorites,
      query: query,
    ) as AzkarBrowsing;

void main() {
  test('a counter tap does not rebuild the azkar scaffold', () {
    final previous = _reciting(const [3]);

    expect(azkarScreenShouldRebuild(previous, _reciting(const [2])), isFalse);
  });

  test('opening another collection rebuilds the scaffold', () {
    final previous = _reciting(const [3]);
    final next = _reciting(const [1], collection: _otherCollection);

    expect(azkarScreenShouldRebuild(previous, next), isTrue);
  });

  test('entering and leaving the reciting view rebuilds', () {
    final browsing = _browsing();
    final reciting = _reciting(const [3]);

    expect(azkarScreenShouldRebuild(browsing, reciting), isTrue);
    expect(azkarScreenShouldRebuild(reciting, browsing), isTrue);
  });

  test('browsing changes (search, pins) always rebuild', () {
    final previous = _browsing();
    final next = _browsing(
      collections: const [_collection, _otherCollection],
      favorites: const {'morning'},
      query: 'ذكر',
    );

    expect(azkarScreenShouldRebuild(previous, next), isTrue);
  });

  test('loading and failure transitions rebuild', () {
    expect(
      azkarScreenShouldRebuild(
        const AzkarState.loading(),
        const AzkarState.failed(),
      ),
      isTrue,
    );
  });
}
