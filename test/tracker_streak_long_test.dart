import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_state.dart';

import 'support/test_db.dart';

void main() {
  test('a streak longer than 400 days is not silently capped', () async {
    final db = newTestDb();
    final repo = PrayerLogRepository(db);
    final now = DateTime.now();
    for (var i = 0; i <= 400; i++) {
      await repo.togglePrayer(now.subtract(Duration(days: i)), PrayerSlot.fajr);
    }

    final cubit = TrackerCubit(repo: repo);
    addTearDown(cubit.close);
    await cubit.start();
    await cubit.loaded;

    expect(
      (cubit.state as TrackerReady).streakDays,
      401,
      reason:
          'the lookback must not decide how long a user can keep a '
          'streak; the old 400-day window truncated it silently',
    );
  });
}
