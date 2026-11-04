import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/reminder_background_task.dart';

void main() {
  test('a completed refresh reports success', () async {
    var runs = 0;

    expect(await runReminderRefreshTask(() async => runs++), isTrue);
    expect(runs, 1);
  });

  test('a failing refresh reports failure instead of throwing', () async {
    // The task body touches the database, the prayer port and the plugin; any
    // of them may fail on a locked or half-migrated install. WorkManager reads
    // `false` as "retry later" — a thrown error is an opaque worker crash.
    expect(
      await runReminderRefreshTask(() async => throw StateError('db locked')),
      isFalse,
    );
  });

  test('the registered names are stable', () {
    // The platform stores the unique name: renaming either value would orphan
    // the periodic task on every installed device instead of updating it.
    expect(reminderRefreshUniqueName, 'quran_yahdi_reminder_refresh');
    expect(reminderRefreshTask, 'reminderRefresh');
    expect(reminderRefreshFrequency, const Duration(minutes: 30));
  });
}
