import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';

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

AzkarRepository _repoA() => AzkarRepository(loader: () async => _root());

void main() {
  test('plain query matches diacritic-heavy item text', () async {
    final results = await _repoA().search('باسمك اللهم');

    expect(results.hits, hasLength(1));
    expect(results.hits.single.collection.id, 'c2');
    expect(results.hits.single.itemIndex, 0);
    expect(results.hits.single.item.text,
        'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا');
    expect(results.hasMore, isFalse);
  });

  test('collection names match too', () async {
    final results = await _repoA().search('النوم');

    expect(results.hits, hasLength(1));
    expect(results.hits.single.collection.id, 'c2');
  });

  test('latin collection names match case-insensitively', () async {
    final results = await _repoA().search('MORNING');

    expect(results.hits, hasLength(2));
    expect(results.hits.map((h) => h.collection.id).toSet(), {'c1'});
  });

  test('an empty or whitespace-only query yields no hits', () async {
    expect((await _repoA().search('')).hits, isEmpty);
    expect((await _repoA().search('   ')).hits, isEmpty);
  });

  test('results are capped at the limit and flag hasMore', () async {
    final repo = AzkarRepository(
        loader: () async => {
              'collections': [
                {
                  'id': 'c',
                  'nameAr': 'أذكار متفرقة',
                  'nameEn': 'General',
                  'items': [
                    for (var i = 0; i < 55; i++)
                      {'text': 'ذِكْرٌ رَقْمُ $i', 'count': 1},
                  ],
                },
              ],
            });

    final results = await repo.search('ذكر', limit: 50);

    expect(results.hits, hasLength(50));
    expect(results.hasMore, isTrue);
  });

  test('exactly the limit is not flagged as truncated', () async {
    final repo = AzkarRepository(
        loader: () async => {
              'collections': [
                {
                  'id': 'c',
                  'nameAr': 'أذكار متفرقة',
                  'nameEn': 'General',
                  'items': [
                    for (var i = 0; i < 50; i++)
                      {'text': 'ذِكْرٌ رَقْمُ $i', 'count': 1},
                  ],
                },
              ],
            });

    final results = await repo.search('ذكر', limit: 50);

    expect(results.hits, hasLength(50));
    expect(results.hasMore, isFalse);
  });
}
