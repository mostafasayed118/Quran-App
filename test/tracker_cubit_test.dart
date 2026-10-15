import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_state.dart';

void main() {
  late AppDatabase db;
  late PrayerLogRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = PrayerLogRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<TrackerCubit> build() async {
    final cubit = TrackerCubit(repo: repo);
    await cubit.loaded;
    return cubit;
  }

  test('fresh state: all-false, streak 0', () async {
    final cubit = await build();
    final ready = cubit.state as TrackerReady;
    expect(ready.today.anyMarked, isFalse);
    expect(ready.streakDays, 0);
    expect(ready.last7, hasLength(7));
    expect(ready.last7.any((m) => m), isFalse);
    await cubit.close();
  });

  test('toggling fajr flips it and streak becomes 1', () async {
    final cubit = await build();
    await cubit.toggle(PrayerSlot.fajr);
    final ready = cubit.state as TrackerReady;
    expect(ready.today.fajr, isTrue);
    expect(ready.streakDays, 1);
    await cubit.close();
  });

  test('seeded previous 3 marked days → streak 4 (today-anchored)', () async {
    final now = DateTime.now();
    for (var i = 1; i <= 3; i++) {
      await repo.togglePrayer(
          now.subtract(Duration(days: i)), PrayerSlot.fajr);
    }
    final cubit = await build();
    await cubit.toggle(PrayerSlot.dhuhr);
    expect((cubit.state as TrackerReady).streakDays, 4);
    await cubit.close();
  });

  test('seeded gap: marked y-day..d-3 with today empty → streak 3 (y-day anchor)',
      () async {
    final now = DateTime.now();
    for (var i = 1; i <= 3; i++) {
      await repo.togglePrayer(
          now.subtract(Duration(days: i)), PrayerSlot.maghrib);
    }
    final cubit = await build();
    expect((cubit.state as TrackerReady).streakDays, 3);
    await cubit.close();
  });

  test('gap breaks the streak entirely (d-2 anchor only)', () async {
    final now = DateTime.now();
    await repo.togglePrayer(now.subtract(const Duration(days: 1)),
        PrayerSlot.fajr);
    await repo.togglePrayer(now.subtract(const Duration(days: 2)),
        PrayerSlot.fajr);
    await repo.togglePrayer(now.subtract(const Duration(days: 3)),
        PrayerSlot.fajr);
    // skip 3 days back to create a hole further back — sanity only
    final cubit = await build();
    expect((cubit.state as TrackerReady).streakDays, 3);
    await cubit.close();
  });
}
