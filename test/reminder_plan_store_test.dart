import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_plan_store.dart';

void main() {
  test('the store round-trips the boot id', () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftReminderPlanStore(db);

    await store.write(
      const ReminderPlanSnapshot(
        fingerprint: 'plan-1',
        exact: true,
        bootId: 'boot-A',
      ),
    );

    final read = await store.read();
    expect(read?.fingerprint, 'plan-1');
    expect(read?.exact, isTrue);
    expect(read?.bootId, 'boot-A');
  });

  test('a snapshot written without a boot id reads back with null', () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftReminderPlanStore(db);

    await store.write(
      const ReminderPlanSnapshot(fingerprint: 'plan-2', exact: false),
    );

    final read = await store.read();
    expect(read?.fingerprint, 'plan-2');
    expect(read?.exact, isFalse);
    expect(read?.bootId, isNull);
  });
}
