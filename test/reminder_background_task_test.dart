import 'dart:io';

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

  test('the stamp keeps a bounded history', () async {
    final file =
        File('${Directory.systemTemp.path}/reminder_refresh_stamp.txt');
    if (file.existsSync()) file.deleteSync();
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    for (var run = 0; run < stampHistory + 5; run++) {
      await stampReminderRefresh('run$run');
    }

    final lines = await file.readAsLines();
    expect(file.existsSync(), isTrue);
    expect(
      lines,
      hasLength(stampHistory),
      reason: 'a task every half hour must not grow an unbounded file',
    );
    expect(lines.last, contains('run${stampHistory + 4}'));
    expect(lines.first, isNot(contains('run0')));
  });
}
