import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

void main() {
  test('schema creates the ayah search table', () async {
    final db = newTestDb();

    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'ayah_search'",
        )
        .get();

    expect(rows, isNotEmpty,
        reason: 'the bundled search index needs its own table');
  });
}
