import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _dailyIds = {
  'daily-home',
  'daily-out',
  'daily-mosque',
  'daily-food',
  'daily-clothing',
  'daily-travel',
  'daily-market',
};

void main() {
  final file = File('assets/data/azkar.json');

  Map<String, dynamic> loadRoot() =>
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  List<Map<String, dynamic>> collectionsOf(Map<String, dynamic> root) =>
      (root['collections'] as List).cast<Map<String, dynamic>>();

  test('the bundled asset parses with unique ids and complete items', () {
    if (!file.existsSync()) {
      markTestSkipped('working dir does not resolve the bundled asset');
    }
    final collections = collectionsOf(loadRoot());

    final ids = <String>[];
    for (final collection in collections) {
      ids.add(collection['id'] as String);
      expect((collection['nameAr'] as String).trim().isNotEmpty, isTrue);
      expect((collection['nameEn'] as String).trim().isNotEmpty, isTrue);
      final items = (collection['items'] as List).cast<Map<String, dynamic>>();
      expect(items, isNotEmpty, reason: 'no items in ${collection['id']}');
      for (final item in items) {
        expect((item['text'] as String).trim().isNotEmpty, isTrue,
            reason: 'empty text in ${collection['id']}');
        final count = item['count'];
        expect(count, isA<int>(),
            reason: 'missing count in ${collection['id']}');
        expect(count as int, greaterThanOrEqualTo(1),
            reason: 'invalid count in ${collection['id']}');
      }
    }
    expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate ids');
  });

  test('daily occasions collections exist with referenced items', () {
    if (!file.existsSync()) {
      markTestSkipped('working dir does not resolve the bundled asset');
    }
    final collections = collectionsOf(loadRoot());
    final daily = {
      for (final collection in collections)
        if ((collection['id'] as String).startsWith('daily-'))
          collection['id'] as String: collection,
    };

    expect(daily.keys.toSet(), _dailyIds);
    for (final entry in daily.entries) {
      final items = (entry.value['items'] as List).cast<Map<String, dynamic>>();
      for (final item in items) {
        final reference = item['reference'] as String?;
        expect(reference, isNotNull,
            reason: 'missing reference in ${entry.key}');
        expect(reference, contains('حصن المسلم'),
            reason: 'unattributed text in ${entry.key}');
      }
    }
  });
}
