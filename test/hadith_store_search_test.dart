import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/library/data/hadith_store.dart';

import 'support/test_db.dart';

void main() {
  late HadithStore store;

  setUp(() async {
    final db = newTestDb();
    store = HadithStore(db, packPath: (_) async => null);
    await store.importProjection('p1', <(int, String)>[
      (1, 'الرَّحْمَةُ'),
      (2, 'الصلاة'),
      (3, 'الصلاة على النبي'),
    ]);
  });

  test('search folds diacritics and letter variants', () async {
    final (items, hasMore) = await store.search('p1', 'الرحمة');

    expect(items, [(1, 'الرَّحْمَةُ')]);
    expect(hasMore, isFalse);
  });

  test('search pages the matches', () async {
    final (first, hasMore) = await store.search('p1', 'الصلاة', limit: 1);
    expect(first, hasLength(1));
    expect(hasMore, isTrue);

    final (second, more) = await store.search(
      'p1',
      'الصلاة',
      offset: 1,
      limit: 1,
    );
    expect(second, hasLength(1));
    expect(more, isFalse);
  });

  test('an empty query matches nothing', () async {
    final (items, hasMore) = await store.search('p1', '   ');
    expect(items, isEmpty);
    expect(hasMore, isFalse);
  });

  test('byNumbers returns book order, not the set order', () async {
    final items = await store.byNumbers('p1', {3, 1});

    expect(items.map((e) => e.$1), [1, 3]);
  });

  test('byNumbers batches past a host-parameter ceiling in book order',
      () async {
    // The DB throws on any statement with >4 variables (Android's 999 ceiling
    // emulated on a larger-limit host): pack_id plus 3 batched numbers. 7
    // numbers must split, then re-merge by ordinal, or it throws / loses order.
    final db = newLimitedVarDb(limit: 4);
    final local = HadithStore(
      db,
      packPath: (_) async => null,
      maxSqlVariables: 3,
    );
    final numbers = List<int>.generate(7, (i) => i + 1);
    await local.importProjection(
      'big',
      [for (final n in numbers) (n, 'حديث $n')],
    );

    final items = await local.byNumbers('big', numbers.toSet());

    expect(items, hasLength(numbers.length));
    expect(items.map((e) => e.$1).toList(), numbers);
  });

  test('a pre-search row is backfilled before matching', () async {
    final db = newTestDb();
    final local = HadithStore(db, packPath: (_) async => null);
    await local.importProjection('p1', <(int, String)>[(1, 'الصلاة')]);
    await db.customStatement(
      'INSERT INTO hadith_entries(pack_id, ordinal, number, body, norm) '
      "VALUES ('p1', 99, 9, 'الرَّحْمَةُ', '')",
    );

    final (items, _) = await local.search('p1', 'الرحمة');

    expect(items, hasLength(1));
    expect(items.single.$1, 9);
  });
}
