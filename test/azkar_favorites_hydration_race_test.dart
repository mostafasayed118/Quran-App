import 'dart:async';

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
        {'text': 'ذِكْرٌ أَوَّل', 'count': 3},
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

/// A source whose first read can be held open, so a tap can land while the
/// stored state is still in flight.
class _GatedSource implements AzkarSavedStateSource {
  _GatedSource(this.stored);

  AzkarSavedState stored;
  Completer<void>? gate;
  int favoriteWrites = 0;

  @override
  Future<AzkarSavedState> load() async {
    // A real read sees the row as of the moment it lands, not after the wait:
    // capture the snapshot before the gate so a tap during the wait cannot
    // reach back into the read.
    final snapshot = stored;
    final pending = gate;
    if (pending != null) await pending.future;
    return snapshot;
  }

  @override
  Future<void> saveRemaining(
    String collectionId,
    List<int> remaining,
    String day,
  ) async {
    stored = AzkarSavedState(
      day: day,
      remaining: {...stored.remaining, collectionId: remaining},
      favorites: stored.favorites,
    );
  }

  @override
  Future<void> saveFavorites(Set<String> favorites) async {
    favoriteWrites++;
    stored = AzkarSavedState(
      day: stored.day,
      remaining: stored.remaining,
      favorites: favorites,
    );
  }
}

Future<AzkarCubit> _startWithGate(_GatedSource source) async {
  final cubit = AzkarCubit(
    repository: AzkarRepository(loader: () async => _catalog()),
    savedState: source,
    clock: () => _now,
  );
  unawaited(cubit.start());
  // Let the catalog emit; the stored-state read is still gated.
  await Future<void>.delayed(Duration.zero);
  return cubit;
}

void main() {
  test(
    'a favourite added while the read is pending survives hydration',
    () async {
      final gate = Completer<void>();
      final source = _GatedSource(const AzkarSavedState(day: _today))
        ..gate = gate;
      final cubit = await _startWithGate(source);
      addTearDown(cubit.close);

      expect((cubit.state as AzkarBrowsing).favorites, isEmpty);
      cubit.toggleFavorite('morning');

      gate.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        (cubit.state as AzkarBrowsing).favorites,
        contains('morning'),
        reason: 'the read must not overwrite a tap that landed while it ran',
      );
    },
  );

  test('a favourite removed while the read is pending stays removed', () async {
    final gate = Completer<void>();
    final source = _GatedSource(
      const AzkarSavedState(day: _today, favorites: {'morning'}),
    )..gate = gate;
    final cubit = await _startWithGate(source);
    addTearDown(cubit.close);

    // The list shows no favourites yet, so the user's first tap adds and the
    // second removes; their final intent is "not a favourite".
    cubit.toggleFavorite('morning');
    cubit.toggleFavorite('morning');

    gate.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      (cubit.state as AzkarBrowsing).favorites,
      isNot(contains('morning')),
      reason:
          'the stored set must not resurrect a favourite the user '
          'removed while the read was in flight',
    );
  });

  test('an untouched favourite comes from the stored state', () async {
    final gate = Completer<void>();
    final source = _GatedSource(
      const AzkarSavedState(day: _today, favorites: {'evening'}),
    )..gate = gate;
    final cubit = await _startWithGate(source);
    addTearDown(cubit.close);

    gate.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as AzkarBrowsing).favorites, {'evening'});
  });

  test(
    'untouched counters come from the stored state after hydration',
    () async {
      final gate = Completer<void>();
      final source = _GatedSource(
        const AzkarSavedState(
          day: _today,
          remaining: {
            'morning': [0],
          },
        ),
      )..gate = gate;
      final cubit = await _startWithGate(source);
      addTearDown(cubit.close);

      final collection = (cubit.state as AzkarBrowsing).collections.first;
      cubit.open(collection);
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as AzkarReciting).remaining, [
        0,
      ], reason: 'the open waits for the read and shows the stored counters');
    },
  );
}
