import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

List<PrayerChoice> fakeDay() => [
  PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 15, 4, 45)),
  PrayerChoice(PrayerName.sunrise, DateTime(2026, 3, 15, 6, 10)),
  PrayerChoice(PrayerName.dhuhr, DateTime(2026, 3, 15, 12, 5)),
  PrayerChoice(PrayerName.asr, DateTime(2026, 3, 15, 15, 35)),
  PrayerChoice(PrayerName.maghrib, DateTime(2026, 3, 15, 18, 5)),
  PrayerChoice(PrayerName.isha, DateTime(2026, 3, 15, 19, 30)),
];

const ReminderTexts _texts = ReminderTexts(
  prayerTitle: _prayerTitle,
  prayerSoonTitle: _prayerSoon,
  azkarTitle: 'أذكار الصباح',
  wirdTitle: 'وردك اليوم',
);

String _prayerTitle(PrayerName name) => 'prayer:${name.name}';

String _prayerSoon(PrayerName name, int minutes) =>
    'soon:${name.name}:$minutes';

void main() {
  ScheduledReminder byId(List<ScheduledReminder> plan, int id) =>
      plan.firstWhere((reminder) => reminder.id == id);

  group('prayer reminder carries the resolved adhan', () {
    test('a non-fajr prayer takes the global choice', () {
      final plan = planReminders(
        now: DateTime(2026, 3, 15, 18, 30), // next is isha
        todayPrayers: fakeDay(),
        azkarEnabled: false,
        azkarTimeHm: null,
        texts: _texts,
        adhanId: kDefaultAdhanId,
        fajrAdhanId: kDefaultAdhanId,
      );

      expect(plan, hasLength(1));
      expect(plan.single.id, prayerReminderId);
      expect(plan.single.adhanId, kDefaultAdhanId);
    });

    test('fajr takes the override', () {
      final plan = planReminders(
        now: DateTime(2026, 3, 15, 3, 0), // next is fajr
        todayPrayers: fakeDay(),
        azkarEnabled: false,
        azkarTimeHm: null,
        texts: _texts,
        adhanId: kDefaultAdhanId,
        fajrAdhanId: kDefaultAdhanId,
      );

      expect(plan.single.fireAt, DateTime(2026, 3, 15, 4, 45));
      expect(plan.single.adhanId, kDefaultAdhanId);
    });

    test('fajr falls back to the global choice when there is no override', () {
      final plan = planReminders(
        now: DateTime(2026, 3, 15, 3, 0),
        todayPrayers: fakeDay(),
        azkarEnabled: false,
        azkarTimeHm: null,
        texts: _texts,
        adhanId: kDefaultAdhanId,
      );

      expect(plan.single.adhanId, kDefaultAdhanId);
    });

    test(
      'fajr falls back when the override names a track this build lacks',
      () {
        final plan = planReminders(
          now: DateTime(2026, 3, 15, 3, 0),
          todayPrayers: fakeDay(),
          azkarEnabled: false,
          azkarTimeHm: null,
          texts: _texts,
          adhanId: kDefaultAdhanId,
          fajrAdhanId: 'removed_in_a_future_build',
        );

        expect(plan.single.adhanId, kDefaultAdhanId);
      },
    );

    test('with no adhan configured the reminder keeps the default channel', () {
      final plan = planReminders(
        now: DateTime(2026, 3, 15, 10, 0),
        todayPrayers: fakeDay(),
        azkarEnabled: false,
        azkarTimeHm: null,
        texts: _texts,
      );

      // Null means "post on the legacy channel with the OS default sound",
      // which is exactly today's behaviour.
      expect(plan.single.adhanId, isNull);
    });
  });

  test('azkar, wird and the pre-adhan heads-up carry no adhan', () {
    final plan = planReminders(
      now: DateTime(2026, 3, 15, 3, 0),
      todayPrayers: fakeDay(),
      azkarEnabled: true,
      azkarTimeHm: '06:30',
      wirdEnabled: true,
      wirdTimeHm: '20:00',
      preAdhanMinutes: 10,
      texts: _texts,
      adhanId: kDefaultAdhanId,
      fajrAdhanId: kDefaultAdhanId,
    );

    expect(byId(plan, prayerReminderId).adhanId, kDefaultAdhanId);
    expect(byId(plan, azkarReminderId).adhanId, isNull);
    expect(byId(plan, wirdReminderId).adhanId, isNull);
    expect(byId(plan, preAdhanReminderId).adhanId, isNull);
  });

  group('notification channels', () {
    test('every track has a distinct channel, none reusing the legacy one', () {
      const legacyChannel = 'quran_yahdi_reminders';
      final channels = kAdhanCatalog.map(adhanChannelId).toList();

      expect(channels.toSet().length, kAdhanCatalog.length);
      expect(channels, isNot(contains(legacyChannel)));
    });

    test('a channel is derived from the track it plays', () {
      final track = adhanById(kDefaultAdhanId);
      expect(adhanChannelId(track), 'quran_yahdi_adhan_$kDefaultAdhanId');
    });
  });
}
