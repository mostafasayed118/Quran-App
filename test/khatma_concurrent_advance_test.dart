import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/tracker/data/khatma_repository.dart';

import 'support/test_db.dart';

void main() {
  test('concurrent advances never move the pointer backwards', () async {
    final db = newTestDb();
    addTearDown(db.close);
    final repo = KhatmaRepository(db);
    await repo.startPlan(10);

    // Interleave a forward and a backward write many times. The conditional
    // UPDATE must keep the maximum regardless of completion order.
    for (var i = 0; i < 20; i++) {
      await Future.wait([
        repo.advanceTo(100 + i),
        repo.advanceTo(50 + i),
      ]);
    }

    final plan = await repo.currentPlan();
    expect(plan?.ayahId, 119);
  });
}
