import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late TasbihRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = TasbihRepository(db);
  });

  test('save/load roundtrips the snapshot in the settings table', () async {
    expect(await repo.load(), isNull);
    await repo.save(17, 99);
    final snapshot = await repo.load();
    expect(snapshot, isNotNull);
    expect(snapshot!.count, 17);
    expect(snapshot.target, 99);

    await repo.save(0, 100);
    final second = await repo.load();
    expect(second!.count, 0);
    expect(second.target, 100);
  });
}
