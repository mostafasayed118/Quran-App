import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';

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

  test('toggle-on persists and re-reads', () async {
    await repo.togglePrayer(DateTime.now(), PrayerSlot.fajr);
    final day = await repo.dayView(DateTime.now());
    expect(day.fajr, isTrue);
    expect(day.dhuhr, isFalse);
    expect(day.anyMarked, isTrue);
  });

  test('toggle-all-off keeps the row; anyMarked=false; row count stays 1', () async {
    final now = DateTime.now();
    for (final slot in PrayerSlot.values) {
      await repo.togglePrayer(now, slot);
    }
    for (final slot in PrayerSlot.values) {
      await repo.togglePrayer(now, slot);
    }
    final day = await repo.dayView(now);
    expect(day.anyMarked, isFalse);
    final rows = await db.select(db.prayerLog).get();
    expect(rows, hasLength(1));
  });

  test('day normalization: raw-now call matches dateOnly row (both ways)',
      () async {
    final now = DateTime.now();

    await repo.togglePrayer(now, PrayerSlot.dhuhr);
    expect(await repo.getForDay(now), isTrue);
    expect(await repo.getForDay(dateOnly(now)), isTrue);

    final laterToday = DateTime(now.year, now.month, now.day, 23, 59);
    expect(await repo.getForDay(laterToday), isTrue);
  });

  test('markedDaysRange returns only marked days, normalized', () async {
    final now = DateTime.now();
    await repo.togglePrayer(now, PrayerSlot.fajr);
    final yesterday = now.subtract(const Duration(days: 1));
    await repo.togglePrayer(yesterday, PrayerSlot.isha);
    final twoDays = now.subtract(const Duration(days: 2));
    await repo.togglePrayer(twoDays, PrayerSlot.asr);
    await repo.togglePrayer(twoDays, PrayerSlot.asr); // flips back off

    final marked = await repo.markedDaysRange(now, 7);
    final keys = marked
        .map((d) => '${d.year}-${d.month}-${d.day}')
        .toSet();
    expect(keys, contains('${now.year}-${now.month}-${now.day}'));
    expect(
        keys,
        contains('${yesterday.year}-${yesterday.month}-${yesterday.day}'));
    expect(keys, hasLength(2));
  });
}
