import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/sql_batching.dart';

void main() {
  test('an empty input yields no batches', () {
    expect(sqlBatches(<int>[]), isEmpty);
  });

  test('a short input is a single batch', () {
    expect(sqlBatches([1, 2, 3]), [
      [1, 2, 3],
    ]);
  });

  test(
    'an input past the SQLite variable limit splits into ordered batches',
    () {
      final ids = List<int>.generate(kMaxSqlVariables + 5, (i) => i + 1);
      final batches = sqlBatches(ids).toList();

      expect(batches, hasLength(2));
      expect(batches.first, hasLength(kMaxSqlVariables));
      expect(batches.last, hasLength(5));
      expect(batches.expand((b) => b).toList(), ids);
    },
  );

  test('an exact multiple never emits an empty trailing batch', () {
    final ids = List<int>.generate(kMaxSqlVariables * 2, (i) => i);
    final batches = sqlBatches(ids).toList();
    expect(batches, hasLength(2));
    expect(batches.every((b) => b.isNotEmpty), isTrue);
  });
}
