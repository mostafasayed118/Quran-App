import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_state.dart';

Map<String, dynamic> _catalog() => {
      'collections': [
        {
          'id': 'morning',
          'nameAr': 'أذكار الصباح',
          'nameEn': 'Morning',
          'items': [
            {'text': 'ذِكْرٌ ثَلَاثٌ', 'count': 3},
            {'text': 'ذِكْرٌ اثْنَان', 'count': 2},
          ],
        },
        {
          'id': 'evening',
          'nameAr': 'أذكار المساء',
          'nameEn': 'Evening',
          'items': [
            {'text': 'ذِكْرٌ وَاحِد', 'count': 1},
          ],
        },
      ],
    };

class _Source implements AzkarSavedStateSource {
  AzkarSavedState stored = const AzkarSavedState();
  bool throwOnLoad = false;
  bool throwOnSave = false;
  int remainingWrites = 0;
  int favoriteWrites = 0;

  @override
  Future<AzkarSavedState> load() async {
    if (throwOnLoad) throw StateError('load');
    return stored;
  }

  @override
  Future<void> saveRemaining(String collectionId, List<int> remaining) async {
    if (throwOnSave) throw StateError('save');
    remainingWrites++;
    stored = AzkarSavedState(
      remaining: {...stored.remaining, collectionId: remaining},
      favorites: stored.favorites,
    );
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) async {
    if (throwOnSave) throw StateError('save');
    favoriteWrites++;
    stored = AzkarSavedState(
      remaining: stored.remaining,
      favorites: favorites,
    );
  }
}

AzkarCubit _cubit({AzkarSavedStateSource? source}) => AzkarCubit(
      repository: AzkarRepository(loader: () async => _catalog()),
      savedState: source,
    );

void main() {
  test('saved counters resume, clamped to each item count', () async {
    final source = _Source()
      ..stored = const AzkarSavedState(
        remaining: {
          'morning': [9, 1],
        },
      );
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    final browsing = cubit.state as AzkarBrowsing;
    cubit.open(browsing.collections.first);

    expect((cubit.state as AzkarReciting).remaining, [3, 1]);
  });

  test('a short saved list fills the missing items with their full count',
      () async {
    final source = _Source()
      ..stored = const AzkarSavedState(
        remaining: {
          'morning': [1],
        },
      );
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);

    expect((cubit.state as AzkarReciting).remaining, [1, 2]);
  });

  test('every tap persists the counters of the open collection', () async {
    final source = _Source();
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.tapItem(0);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as AzkarReciting).remaining, [2, 2]);
    expect(source.stored.remaining['morning'], [2, 2]);
    expect(source.remainingWrites, 1);
  });

  test('restart resets every counter to full and persists it', () async {
    final source = _Source()
      ..stored = const AzkarSavedState(
        remaining: {
          'morning': [0, 1],
        },
      );
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.restart();
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as AzkarReciting).remaining, [3, 2]);
    expect(source.stored.remaining['morning'], [3, 2]);
  });

  test('a failing write never breaks the counter', () async {
    final source = _Source()..throwOnSave = true;
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.tapItem(0);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as AzkarReciting).remaining, [2, 2]);
  });

  test('a failing read falls back to full counters', () async {
    final source = _Source()..throwOnLoad = true;
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(cubit.state, isA<AzkarBrowsing>());
    cubit.open((cubit.state as AzkarBrowsing).collections.first);

    expect((cubit.state as AzkarReciting).remaining, [3, 2]);
  });

  test('without a source the counters still work in memory', () async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.tapItem(1);

    expect((cubit.state as AzkarReciting).remaining, [3, 1]);
  });

  test('pinned collections sort first and the pin is persisted', () async {
    final source = _Source();
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    final ids = (cubit.state as AzkarBrowsing)
        .collections
        .map((collection) => collection.id)
        .toList();
    expect(ids, ['morning', 'evening']);

    cubit.toggleFavorite('evening');
    await Future<void>.delayed(Duration.zero);

    final browsing = cubit.state as AzkarBrowsing;
    expect(
      browsing.collections.map((collection) => collection.id),
      ['evening', 'morning'],
    );
    expect(browsing.favorites, {'evening'});
    expect(source.stored.favorites, {'evening'});
    expect(source.favoriteWrites, 1);
  });

  test('unpinning restores the catalog order', () async {
    final source = _Source()
      ..stored = const AzkarSavedState(favorites: {'evening'});
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(
      (cubit.state as AzkarBrowsing)
          .collections
          .map((collection) => collection.id),
      ['evening', 'morning'],
    );

    cubit.toggleFavorite('evening');
    await Future<void>.delayed(Duration.zero);

    expect(
      (cubit.state as AzkarBrowsing)
          .collections
          .map((collection) => collection.id),
      ['morning', 'evening'],
    );
    expect(source.stored.favorites, isEmpty);
  });

  test('the pin survives leaving and reopening the collection', () async {
    final source = _Source();
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.toggleFavorite('morning');
    await Future<void>.delayed(Duration.zero);
    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    expect(cubit.state, isA<AzkarReciting>());

    cubit.back();
    await Future<void>.delayed(Duration.zero);
    final browsing = cubit.state as AzkarBrowsing;
    expect(browsing.favorites, {'morning'});
    expect(browsing.collections.first.id, 'morning');
  });
}
