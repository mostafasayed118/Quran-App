import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_state.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late PrayerLogRepository repo;

  setUp(() {
    db = newTestDb();
    repo = PrayerLogRepository(db);
  });

  test('today and yesterday mark last7 and both count toward the streak',
      () async {
    final now = DateTime(2026, 6, 15, 10, 30);
    await repo.togglePrayer(DateTime(2026, 6, 15), PrayerSlot.fajr);
    await repo.togglePrayer(DateTime(2026, 6, 14), PrayerSlot.dhuhr);

    final cubit = TrackerCubit(repo: repo, clock: () => now);
    await cubit.loaded;

    final ready = cubit.state as TrackerReady;
    expect(ready.last7, hasLength(7));
    expect(ready.last7[0], isTrue);
    expect(ready.last7[1], isTrue);
    expect(ready.last7.skip(2), everyElement(isFalse));
    expect(ready.streakDays, 2);

    await cubit.close();
  });
}
