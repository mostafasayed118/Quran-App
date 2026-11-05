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
