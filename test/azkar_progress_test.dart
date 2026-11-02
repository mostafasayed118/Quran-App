import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_saved_state.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_state.dart';

const String _today = '2026-11-02';
final DateTime _now = DateTime(2026, 11, 2, 9);

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
  _Source({this.alwaysReturnsInitialLoad = false});

  AzkarSavedState stored = const AzkarSavedState();

  /// Simulates a read that lands before an in-flight write: the load returns
  /// whatever the first read saw.
  final bool alwaysReturnsInitialLoad;
  late final AzkarSavedState _firstLoad = stored;

  bool throwOnLoad = false;
  bool throwOnSave = false;
  int remainingWrites = 0;
  int favoriteWrites = 0;

  @override
  Future<AzkarSavedState> load() async {
    if (throwOnLoad) throw StateError('load');
    return alwaysReturnsInitialLoad ? _firstLoad : stored;
  }

  @override
  Future<void> saveRemaining(
    String collectionId,
    List<int> remaining,
    String day,
  ) async {
    if (throwOnSave) throw StateError('save');
    remainingWrites++;
    final counts = stored.day == day
        ? <String, List<int>>{...stored.remaining}
        : <String, List<int>>{};
    counts[collectionId] = remaining;
    stored = AzkarSavedState(
      day: day,
      remaining: counts,
      favorites: stored.favorites,
    );
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) async {
    if (throwOnSave) throw StateError('save');
    favoriteWrites++;
    stored = AzkarSavedState(
      day: stored.day,
      remaining: stored.remaining,
      favorites: favorites,
    );
  }
}

AzkarCubit _cubit(
        {AzkarSavedStateSource? source, DateTime Function()? clock}) =>
    AzkarCubit(
      repository: AzkarRepository(loader: () async => _catalog()),
      savedState: source,
      clock: clock ?? () => _now,
    );

void main() {
  test('saved counters resume, clamped to each item count', () async {
    final source = _Source()
      ..stored = const AzkarSavedState(
        day: _today,
        remaining: {
          'morning': [9, 1],
        },
      );
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);

    expect((cubit.state as AzkarReciting).remaining, [3, 1]);
  });

  test('a short saved list fills the missing items with their full count',
      () async {
    final source = _Source()
      ..stored = const AzkarSavedState(
        day: _today,
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

  test('counters stored on an earlier day open at full again', () async {
    final source = _Source()
      ..stored = const AzkarSavedState(
        day: '2026-11-01',
        remaining: {
          'morning': [0, 0],
        },
        favorites: {'morning'},
      );
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    final browsing = cubit.state as AzkarBrowsing;
    expect(browsing.favorites, {'morning'}, reason: 'pins are not daily');
    cubit.open(browsing.collections.first);

    expect((cubit.state as AzkarReciting).remaining, [3, 2]);
  });

  test('a session that crosses midnight does not carry yesterday counters',
      () async {
    var now = DateTime(2026, 11, 2, 23, 55);
    final source = _Source();
    final cubit = _cubit(source: source, clock: () => now);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.tapItem(0);
    await Future<void>.delayed(Duration.zero);
    expect(source.stored.remaining['morning'], [2, 2]);

    now = DateTime(2026, 11, 3, 0, 5);
    cubit.back();
    await Future<void>.delayed(Duration.zero);
    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.tapItem(1);
    await Future<void>.delayed(Duration.zero);

    expect(source.stored.day, '2026-11-03');
    expect(source.stored.remaining.keys, ['morning']);
    cubit.back();
    await Future<void>.delayed(Duration.zero);
    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    expect(
      (cubit.state as AzkarReciting).remaining,
      [3, 1],
      reason: 'yesterday morning counters are not relabelled as today',
    );
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
    expect(source.stored.day, _today);
    expect(source.stored.remaining['morning'], [2, 2]);
    expect(source.remainingWrites, 1);
  });

  test('a tap followed by back is not resurrected by a stale read', () async {
    final source = _Source(alwaysReturnsInitialLoad: true);
    final cubit = _cubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    cubit.tapItem(0);
    cubit.back();
    await Future<void>.delayed(Duration.zero);

    cubit.open((cubit.state as AzkarBrowsing).collections.first);
    expect((cubit.state as AzkarReciting).remaining, [2, 2]);
  });

  test('restart resets every counter to full and persists it', () async {
    final source = _Source()
      ..stored = const AzkarSavedState(
        day: _today,
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
