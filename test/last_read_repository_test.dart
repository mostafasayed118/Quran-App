import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';

void main() {
  late AppDatabase db;
  late LastReadRepository repo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = LastReadRepository(db);
  });

  tearDown(() async => db.close());

  test('save overwrites; load returns null when unset', () async {
    expect(await repo.loadAyahId(), isNull);
    await repo.saveAyahId(8);
    expect(await repo.loadAyahId(), 8);
    await repo.saveAyahId(102);
    expect(await repo.loadAyahId(), 102);
  });
}
