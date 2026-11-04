import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';

String _prayerTitle(PrayerName name) => 'prayer ${name.name}';
String _soonTitle(PrayerName name, int minutes) => 'soon ${name.name} $minutes';

const ReminderTexts _texts = ReminderTexts(
  prayerTitle: _prayerTitle,
  prayerSoonTitle: _soonTitle,
  azkarTitle: 'azkar',
  wirdTitle: 'wird',
);

/// The six times of [day], at fixed clock values.
List<PrayerChoice> _day(DateTime day) => <PrayerChoice>[
      PrayerChoice(
          PrayerName.fajr, DateTime(day.year, day.month, day.day, 4, 45)),
      PrayerChoice(
          PrayerName.sunrise, DateTime(day.year, day.month, day.day, 6, 10)),
      PrayerChoice(
          PrayerName.dhuhr, DateTime(day.year, day.month, day.day, 12, 5)),
      PrayerChoice(
          PrayerName.asr, DateTime(day.year, day.month, day.day, 15, 35)),
      PrayerChoice(
          PrayerName.maghrib, DateTime(day.year, day.month, day.day, 18, 5)),
      PrayerChoice(
          PrayerName.isha, DateTime(day.year, day.month, day.day, 19, 30)),
    ];

List<List<PrayerChoice>> _window(DateTime first,
        {int days = reminderHorizonDays}) =>
    <List<PrayerChoice>>[
      for (var offset = 0; offset < days; offset++)
        _day(DateTime(first.year, first.month, first.day + offset)),
    ];

class _City implements CitySource {
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

class _DayPrayer implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      _day(dayLocal);
  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    final next =
        DateTime(whenLocal.year, whenLocal.month, whenLocal.day + 1, 4, 45);
    return PrayerChoice(PrayerName.fajr, next);
  }
}

class _Settings implements ReminderSettingsPort {
  @override
  Future<bool> azkarEnabled() async => true;
  @override
  Future<String?> azkarTimeHm() async => '06:30';
  @override
  Future<bool> wirdEnabled() async => true;
  @override
  Future<String?> wirdTimeHm() async => '20:00';
  @override
  Future<void> setAzkarEnabled(bool enabled) async {}
  @override
  Future<void> setAzkarTime(String hm) async {}
  @override
  Future<void> setWirdEnabled(bool enabled) async {}
  @override
  Future<void> setWirdTime(String hm) async {}
  @override
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) async {}
}

class _Scheduler implements ReminderSchedulerPort {
  List<ScheduledReminder>? plan;
  @override
  Future<bool> ensurePermissions() async => true;
  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    plan = List<ScheduledReminder>.of(reminders);
  }
}

void main() {
  final now = DateTime(2026, 3, 15, 10, 0);

  test('the horizon covers the whole window except the seed prayer', () {
    final plan = planPrayerHorizon(
      now: now,
      days: _window(now),
      skipAt: DateTime(2026, 3, 15, 12, 5),
      texts: _texts,
    );

    // Seven days of five prayers, minus the one the seed already scheduled,
    // minus today's fajr and sunrise (both already passed).
    expect(plan, hasLength(7 * 5 - 2));
    expect(
      plan.map((r) => r.fireAt).toSet(),
      hasLength(plan.length),
      reason: 'one alarm per instant: a duplicate notifies twice',
    );
    expect(
      plan.map((r) => r.id).toSet(),
      hasLength(plan.length),
      reason: 'the ids are the platform dedupe key',
    );
    expect(
      plan.map((r) => r.title),
      isNot(contains('prayer sunrise')),
      reason: 'sunrise is a marker, never a reminder',
    );
  });

  test('nothing in the horizon fires in the past', () {
    final plan = planPrayerHorizon(now: now, days: _window(now), texts: _texts);

    expect(plan.every((r) => r.fireAt.isAfter(now)), isTrue);
  });

  test('the window reaches the last prayer of the last day', () {
    final plan = planPrayerHorizon(now: now, days: _window(now), texts: _texts);

    final last = DateTime(2026, 3, 21, 19, 30);
    expect(plan.map((r) => r.fireAt), contains(last));
    expect(plan.every((r) => !r.fireAt.isAfter(last)), isTrue);
  });

  test('ids are stable for the same day and reused only a window apart', () {
    final first =
        planPrayerHorizon(now: now, days: _window(now), texts: _texts);
    final second =
        planPrayerHorizon(now: now, days: _window(now), texts: _texts);

    expect(
      first.map((r) => r.id).toSet(),
      second.map((r) => r.id).toSet(),
      reason: 'a re-plan on the same day must replace, never duplicate',
    );
    // The universe is bounded on purpose: a slot is reused once the day that
    // held it left the window, so the binding can clear every possible alarm
    // without remembering the previous plan.
    expect(
      prayerAlarmId(DateTime(2026, 3, 15), PrayerName.fajr),
      prayerAlarmId(DateTime(2026, 3, 22), PrayerName.fajr),
    );
    expect(
      prayerAlarmId(DateTime(2026, 3, 15), PrayerName.fajr),
      isNot(prayerAlarmId(DateTime(2026, 3, 16), PrayerName.fajr)),
    );
  });

  test('no horizon id collides with the frozen ids', () {
    final plan = planPrayerHorizon(
      now: now,
      days: _window(now),
      preAdhanMinutes: 20,
      texts: _texts,
    );

    expect(
      plan.map((r) => r.id).toSet(),
      isNot(contains(anyOf(1, 2, 3, 4))),
    );
    expect(
      reminderAlarmIds().containsAll(plan.map((r) => r.id)),
      isTrue,
      reason: 'a plan must never write an id the clear cannot remove',
    );
  });

  test('disabled prayers are skipped', () {
    final plan = planPrayerHorizon(
      now: now,
      days: _window(now),
      enabledPrayers: {PrayerName.fajr, PrayerName.isha},
      texts: _texts,
    );

    expect(plan.map((r) => r.title).toSet(), {'prayer fajr', 'prayer isha'});
    // Today's fajr already passed, so six fajr + seven isha remain.
    expect(plan, hasLength(6 + 7));
  });

  test('the pre-adhan lead is scheduled for every day of the window', () {
    final plan = planPrayerHorizon(
      now: now,
      days: _window(now),
      skipAt: DateTime(2026, 3, 15, 12, 5),
      preAdhanMinutes: 20,
      texts: _texts,
    );

    final soon = plan.where((r) => r.title.startsWith('soon ')).toList();
    // One per scheduled prayer: the seed prayer and its lead are the seed's.
    expect(soon, hasLength(plan.length - soon.length));
    expect(
      soon.map((r) => r.fireAt),
      containsAll([
        DateTime(2026, 3, 16, 4, 25),
        DateTime(2026, 3, 21, 19, 10),
      ]),
    );
    // A lead time already in the past is dropped, never posted late.
    expect(soon.every((r) => r.fireAt.isAfter(now)), isTrue);
  });

  test('the fajr adhan override follows every fajr of the window', () {
    final plan = planPrayerHorizon(
      now: now,
      days: _window(now),
      adhanId: 'khushu',
      fajrAdhanId: 'islam_sobhy',
      texts: _texts,
    );

    final fajr = plan.where((r) => r.title == 'prayer fajr');
    expect(fajr, isNotEmpty);
    expect(fajr.every((r) => r.adhanId == 'islam_sobhy'), isTrue);
    expect(
      plan
          .where((r) => r.title != 'prayer fajr')
          .every((r) => r.adhanId == 'khushu'),
      isTrue,
    );
  });

  test('azkar and wird repeat daily; a prayer reminder never does', () {
    final plan = planReminders(
      now: now,
      todayPrayers: _day(now),
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      wirdEnabled: true,
      wirdTimeHm: '20:00',
      texts: _texts,
    );

    final prayer = plan.singleWhere((r) => r.id == prayerReminderId);
    expect(prayer.repeatsDaily, isFalse);
    expect(
      plan.where((r) => r.id != prayerReminderId).every((r) => r.repeatsDaily),
      isTrue,
    );
  });

  test('the shared schedule path ships a full window for a real day source',
      () async {
    final scheduler = _Scheduler();

    final plan = await scheduleReminders(
      city: _City(),
      prayer: _DayPrayer(),
      settings: _Settings(),
      scheduler: scheduler,
      now: now,
    );

    expect(scheduler.plan, isNotNull);
    expect(plan.map((r) => r.fireAt).toSet(), hasLength(plan.length));

    // The seed stays the single next prayer, with its frozen id.
    final seed = plan.singleWhere((r) => r.id == prayerReminderId);
    expect(seed.fireAt, DateTime(2026, 3, 15, 12, 5));

    // Beyond the seed, the window carries the rest of today and six more days.
    final prayerInstants = plan
        .where((r) => r.payload == prayerReminderPayload)
        .map((r) => r.fireAt)
        .toList();
    expect(prayerInstants, contains(DateTime(2026, 3, 15, 19, 30)));
    expect(prayerInstants, contains(DateTime(2026, 3, 16, 4, 45)));
    expect(prayerInstants, contains(DateTime(2026, 3, 21, 19, 30)));
    // 35 prayers in the window, minus the seed, minus today's two past ones.
    expect(prayerInstants, hasLength(7 * 5 - 1));

    // Azkar + wird keep their fixed ids and their daily repeat.
    expect(plan.where((r) => r.repeatsDaily), hasLength(2));
  });
}
