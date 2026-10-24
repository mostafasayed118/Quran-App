import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_state.dart';

class GatedToggleRepository implements PrayerLogRepository {
  final Completer<void> gate = Completer<void>();
  int writes = 0;
  DateTime? lastWriteDay;

  @override
  Future<TrackerDay> dayView(DateTime day) async =>
      TrackerDay.empty(DateTime(day.year, day.month, day.day));

  @override
  Future<bool> getForDay(DateTime day) async => false;

  @override
  Future<List<DateTime>> markedDaysRange(
          DateTime fromInclusive, int daysBack) async =>
      const <DateTime>[];

  @override
  Future<void> togglePrayer(DateTime day, PrayerSlot slot) async {
    writes++;
    lastWriteDay = day;
    await gate.future;
  }
}

class GatedReloadRepository implements PrayerLogRepository {
  final Completer<void> firstReload = Completer<void>();
  final Completer<void> secondReload = Completer<void>();
  int dayViewCalls = 0;

  @override
  Future<TrackerDay> dayView(DateTime day) async {
    dayViewCalls++;
    final call = dayViewCalls;
    if (call == 2) await firstReload.future;
    if (call == 3) await secondReload.future;
    return TrackerDay.empty(DateTime(2026, 1, call));
  }

  @override
  Future<bool> getForDay(DateTime day) async => false;

  @override
  Future<List<DateTime>> markedDaysRange(
          DateTime fromInclusive, int daysBack) async =>
      const <DateTime>[];

  @override
  Future<void> togglePrayer(DateTime day, PrayerSlot slot) async {}
}

void main() {
  test('two same-slot taps leave exactly one write', () async {
    final repo = GatedToggleRepository();
    final cubit = TrackerCubit(
      repo: repo,
      clock: () => DateTime(2026, 6, 15, 10, 30),
    );
    await cubit.loaded;

    final first = cubit.toggle(PrayerSlot.fajr);
    await cubit.toggle(PrayerSlot.fajr);
    expect(repo.writes, 1);
    expect(repo.lastWriteDay, DateTime(2026, 6, 15, 10, 30));

    repo.gate.complete();
    await first;
    expect(repo.writes, 1);

    await cubit.toggle(PrayerSlot.dhuhr);
    expect(repo.writes, 2);

    await cubit.close();
  });

  test('an older overlapping reload cannot emit last', () async {
    final repo = GatedReloadRepository();
    final cubit = TrackerCubit(repo: repo);
    await cubit.loaded;
    expect(repo.dayViewCalls, 1);

    final older = cubit.reload();
    final newer = cubit.reload();
    expect(repo.dayViewCalls, 3);

    repo.secondReload.complete();
    await newer;
    expect((cubit.state as TrackerReady).today.day, DateTime(2026, 1, 3));

    repo.firstReload.complete();
    await older;
    expect((cubit.state as TrackerReady).today.day, DateTime(2026, 1, 3));

    await cubit.close();
  });
}
