import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/pre_adhan_canceller.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart'
    show prayerReminderId, preAdhanReminderId;
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';

import 'support/test_db.dart';

class _City implements CitySource {
  const _City();

  @override
  Future<City?> selectedCity() async => const City(
        id: 'cairo',
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        lat: 30.0444,
        lng: 31.2357,
      );

  @override
  Future<void> select(City city) async {}
}

class _Prayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime day) => [
        PrayerChoice(
            PrayerName.fajr, DateTime(day.year, day.month, day.day, 5)),
        PrayerChoice(
            PrayerName.sunrise, DateTime(day.year, day.month, day.day, 6)),
        PrayerChoice(
            PrayerName.dhuhr, DateTime(day.year, day.month, day.day, 12)),
        PrayerChoice(
            PrayerName.asr, DateTime(day.year, day.month, day.day, 15)),
        PrayerChoice(
            PrayerName.maghrib, DateTime(day.year, day.month, day.day, 17, 30)),
        PrayerChoice(
            PrayerName.isha, DateTime(day.year, day.month, day.day, 19)),
      ];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.fajr, whenLocal.add(const Duration(hours: 1)));
}

class _PrayerEmptyTomorrow extends _Prayer {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime day) =>
      day.day == 1 ? super.today(c, day) : const [];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.dhuhr, DateTime(2026, 11, 2, 12));
}

/// Fajr exactly [fajr] today, every other prayer far in the future so Fajr is
/// the chosen reminder regardless of the wall clock.
class _PrayerAt implements PrayerTimesPort {
  const _PrayerAt(this.fajr);

  final DateTime fajr;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime day) => [
        PrayerChoice(PrayerName.fajr, fajr),
        PrayerChoice(
            PrayerName.dhuhr, DateTime(day.year, day.month, day.day, 23, 59)),
      ];

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      PrayerChoice(PrayerName.dhuhr, fajr.add(const Duration(hours: 6)));
}

class _Scheduler implements ReminderSchedulerPort {
  List<ScheduledReminder>? plan;
  int calls = 0;

  /// Optional gate the test uses to hold one schedule in flight.
  Future<void> Function()? onCall;

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    calls++;
    final gate = onCall;
    if (gate != null) await gate();
    plan = reminders;
  }
}

class _Config implements PrayerConfigSource {
  _Config(this._current);

  PrayerConfig _current;

  @override
  PrayerConfig get current => _current;

  @override
  Stream<PrayerConfig> get changes => const Stream.empty();

  @override
  Future<PrayerConfig> load() async => _current;

  @override
  Future<void> save(PrayerConfig config) async {
    _current = config;
  }
}

class _Canceller implements PreAdhanCanceller {
  int calls = 0;

  @override
  Future<void> cancelPreAdhan() async {
    calls++;
  }
}

void main() {
  test('only Dhuhr enabled after Isha schedules tomorrow Dhuhr', () async {
    final scheduler = _Scheduler();
    final settings = ReminderSettings(newTestDb());
    const config = PrayerConfig(
      enabledPrayers: {PrayerName.dhuhr},
    );

    await scheduleReminders(
      city: const _City(),
      prayer: _Prayer(),
      settings: settings,
      scheduler: scheduler,
      now: DateTime(2026, 11, 1, 20),
      config: config,
    );

    final plan = scheduler.plan;
    expect(plan, isNotNull);
    final prayer = plan!.singleWhere((r) => r.id == prayerReminderId);
    expect(prayer.fireAt, DateTime(2026, 11, 2, 12));
  });

  test('a partial future day falls back to the next-prayer contract', () async {
    final scheduler = _Scheduler();
    final settings = ReminderSettings(newTestDb());
    const config = PrayerConfig(
      enabledPrayers: {PrayerName.dhuhr},
    );

    await scheduleReminders(
      city: const _City(),
      prayer: _PrayerEmptyTomorrow(),
      settings: settings,
      scheduler: scheduler,
      now: DateTime(2026, 11, 1, 20),
      config: config,
    );

    final prayer = scheduler.plan!.singleWhere((r) => r.id == prayerReminderId);
    expect(prayer.fireAt, DateTime(2026, 11, 2, 12));
  });

  test('a zero pre-adhan config clears the optional alarm', () async {
    final canceller = _Canceller();
    final settings = ReminderSettings(
      newTestDb(),
      prayerConfig: _Config(PrayerConfig.egyptian),
      preAdhanCanceller: canceller,
    );

    await settings.reschedule(
      city: const _City(),
      prayer: _Prayer(),
      scheduler: _Scheduler(),
    );

    expect(canceller.calls, 1);
  });

  test('a positive pre-adhan config schedules the optional alarm', () async {
    final scheduler = _Scheduler();
    final settings = ReminderSettings(newTestDb());
    const config = PrayerConfig(
      enabledPrayers: {PrayerName.dhuhr},
      preAdhanMinutes: 10,
    );

    await scheduleReminders(
      city: const _City(),
      prayer: _Prayer(),
      settings: settings,
      scheduler: scheduler,
      now: DateTime(2026, 11, 1, 20),
      config: config,
    );

    final soon = scheduler.plan!
        .singleWhere((reminder) => reminder.id == preAdhanReminderId);
    expect(soon.fireAt, DateTime(2026, 11, 2, 11, 50));
  });

  test('a plan that omits the optional alarm still clears it', () async {
    // Same branch as the zero-lead case but reached with a positive lead: the
    // chosen prayer is close enough that its pre-adhan instant has passed, so
    // the planner drops id 4 while the stored setting still enables it. After
    // a restart the binding has no memory of the previous plan, so the clear
    // has to come from the plan itself.
    final canceller = _Canceller();
    final settings = ReminderSettings(
      newTestDb(),
      prayerConfig: _Config(
        const PrayerConfig(
            enabledPrayers: {PrayerName.fajr}, preAdhanMinutes: 15),
      ),
      preAdhanCanceller: canceller,
    );
    final scheduler = _Scheduler();
    final now = DateTime.now();

    await settings.reschedule(
      city: const _City(),
      prayer: _PrayerAt(now.add(const Duration(minutes: 5))),
      scheduler: scheduler,
    );

    expect(scheduler.plan?.any((r) => r.id == preAdhanReminderId), isFalse);
    expect(canceller.calls, 1);
  });

  test('overlapping reschedules serialize instead of interleaving', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final scheduler = _Scheduler();
    scheduler.onCall = () async {
      if (scheduler.calls == 1) {
        entered.complete();
        await release.future;
      }
    };
    final settings = ReminderSettings(newTestDb());

    final first = settings.reschedule(
      city: const _City(),
      prayer: _Prayer(),
      scheduler: scheduler,
    );
    await entered.future;
    final second = settings.reschedule(
      city: const _City(),
      prayer: _Prayer(),
      scheduler: scheduler,
    );
    await Future<void>.delayed(Duration.zero);

    expect(scheduler.calls, 1,
        reason: 'the second replan waits for the first to finish');
    release.complete();
    await Future.wait([first, second]);
    expect(scheduler.calls, 2);
  });
}
