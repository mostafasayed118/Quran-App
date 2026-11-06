import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';

List<PrayerChoice> _day(DateTime date) => [
      PrayerChoice(
        PrayerName.fajr,
        DateTime(date.year, date.month, date.day, 4, 45),
      ),
      PrayerChoice(
        PrayerName.sunrise,
        DateTime(date.year, date.month, date.day, 6, 10),
      ),
      PrayerChoice(
        PrayerName.dhuhr,
        DateTime(date.year, date.month, date.day, 11, 40),
      ),
      PrayerChoice(
        PrayerName.asr,
        DateTime(date.year, date.month, date.day, 14, 42),
      ),
      PrayerChoice(
        PrayerName.maghrib,
        DateTime(date.year, date.month, date.day, 17, 4),
      ),
      PrayerChoice(
        PrayerName.isha,
        DateTime(date.year, date.month, date.day, 18, 24),
      ),
    ];

ReminderTexts _texts({String? followUpTitle}) => ReminderTexts(
      prayerTitle: (prayer) => 'prayer ${prayer.name}',
      azkarTitle: 'azkar',
      fajrFollowUpTitle: followUpTitle,
    );

void main() {
  final day = DateTime(2026, 11, 6);
  final now = DateTime(2026, 11, 6, 3);

  test('the follow-up is opt-in: no title means the historical plan', () {
    final plan = planPrayerHorizon(
      now: now,
      days: [_day(day)],
      texts: _texts(),
    );

    expect(
      plan.where((r) => r.id == fajrFollowUpAlarmId(day, 0)),
      isEmpty,
    );
    expect(
      plan.where((r) => r.id == fajrFollowUpAlarmId(day, 1)),
      isEmpty,
    );
  });

  test('enabling it adds exactly two bounded nudges after Fajr', () {
    final plan = planPrayerHorizon(
      now: now,
      days: [_day(day)],
      texts: _texts(followUpTitle: 'Fajr reminder'),
    );

    final followUps = [
      for (final reminder in plan)
        if (reminder.id == fajrFollowUpAlarmId(day, 0) ||
            reminder.id == fajrFollowUpAlarmId(day, 1))
          reminder,
    ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));

    expect(followUps, hasLength(2));
    expect(followUps[0].fireAt, DateTime(2026, 11, 6, 4, 50));
    expect(followUps[1].fireAt, DateTime(2026, 11, 6, 4, 55));
    expect(followUps[0].title, 'Fajr reminder');
    expect(followUps[0].payload, prayerReminderPayload);
  });

  test('a nudge already in the past is skipped', () {
    final plan = planPrayerHorizon(
      now: DateTime(2026, 11, 6, 4, 52),
      days: [_day(day)],
      texts: _texts(followUpTitle: 'Fajr reminder'),
    );

    expect(
      plan.where((r) => r.id == fajrFollowUpAlarmId(day, 0)),
      isEmpty,
    );
    expect(
      plan.where((r) => r.id == fajrFollowUpAlarmId(day, 1)),
      hasLength(1),
    );
  });

  test('every follow-up id is in the replace-all clear set', () {
    final ids = reminderAlarmIds();

    expect(ids, contains(fajrFollowUpAlarmId(day, 0)));
    expect(ids, contains(fajrFollowUpAlarmId(day, 1)));
  });

  test('the prayer config persists the opt-in flag', () {
    const config = PrayerConfig(fajrFollowUp: true);

    expect(PrayerConfig.fromJson(config.toJson()).fajrFollowUp, isTrue);
    expect(PrayerConfig.fromJson(const {}).fajrFollowUp, isFalse);
    expect(
      config.copyWith(fajrFollowUp: false).fajrFollowUp,
      isFalse,
    );
  });
}
