import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';

Map<String, dynamic> fixtureRoot() => {
      'collections': [
        {
          'id': 'c1',
          'nameAr': 'أذكار الصباح',
          'nameEn': 'Morning',
          'items': [
            {'text': 'ذِكْرٌ أَوَّلٌ'},
            {'text': 'ذِكْرٌ ثَانٍ', 'count': 3, 'virtue': 'فضل الذكر'},
          ],
        },
        {
          'id': 'c2',
          'nameAr': 'أذكار المساء',
          'nameEn': 'Evening',
          'items': [
            {'text': 'ذِكْرٌ ثَالِثٌ', 'count': 7},
          ],
        },
      ],
    };

void main() {
  late AzkarRepository repo;

  setUp(() {
    repo = AzkarRepository(loader: () async => fixtureRoot());
  });

  test('parses collections and coerces missing count to default 1', () async {
    final collections = await repo.collections();
    expect(collections, hasLength(2));
    expect(collections[0].items[0].count, 1);
    expect(collections[0].items[1].count, 3);
    expect(collections[0].items[1].virtue, 'فضل الذكر');
  });

  test('collection lookup by id', () async {
    final collections = await repo.collections();
    final evening = collections.firstWhere((c) => c.id == 'c2',
        orElse: () => throw StateError('missing c2'));
    expect(evening.nameEn, 'Evening');
    expect(evening.items.single.count, 7);
  });

  test('bundled azkar asset is well-formed (>=6 collections, >=60 items)', () {
    final file = File('assets/data/azkar.json');
    if (!file.existsSync()) {
      markTestSkipped(
          'working dir does not resolve the bundled asset from this runner');
    }
    final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final list = (root['collections'] as List).cast<Map<String, dynamic>>();
    expect(list.length, greaterThanOrEqualTo(6));

    var totalItems = 0;
    for (final c in list) {
      expect((c['id'] as String).isNotEmpty, isTrue);
      expect((c['nameAr'] as String).isNotEmpty, isTrue);
      expect((c['nameEn'] as String).isNotEmpty, isTrue);
      final items = (c['items'] as List).cast<Map<String, dynamic>>();
      totalItems += items.length;
      for (final item in items) {
        expect((item['text'] as String).trim().isNotEmpty, isTrue,
            reason: 'empty text in ${c['id']}');
        final count = item['count'] as int?;
        if (count != null) {
          expect(count, greaterThanOrEqualTo(1));
        }
      }
    }
    expect(totalItems, greaterThanOrEqualTo(60));
  });
}
