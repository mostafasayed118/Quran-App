import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/core/l10n/platform_localizations.dart';
import 'package:quran_yahdi/core/l10n/prayer_names.dart';
import 'package:quran_yahdi/core/utils/arabic_numbers.dart';

import 'reminder_planner.dart';

/// Shared (re)schedule path for boot, the prayer-times cubit and the settings
/// cubit: reads the persisted city + reminder settings, composes the plan with
/// the app's pinned AR strings and hands it to the scheduler. Best-effort by
/// design — never throws (W7b v1).
///
/// Returns the plan the scheduler received (empty when the read or the
/// schedule failed), so the caller can tell whether an optional reminder made
/// it into the new plan.
Future<List<ScheduledReminder>> scheduleReminders({
  required CitySource city,
  required PrayerTimesPort prayer,
  required ReminderSettingsPort settings,
  required ReminderSchedulerPort scheduler,
  bool prayerEnabled = true,
  PrayerConfig config = PrayerConfig.egyptian,
  DateTime? now,
  AdhanPreferences? adhanPrefs,
}) async {
  try {
    final selected = await city.selectedCity();
    final nowLocal = now ?? DateTime.now();
    final todayPrayers = selected == null
        ? const <PrayerChoice>[]
        : prayer.today(selected.coordinates, nowLocal);
    final hasFuturePrayer = todayPrayers.any(
      (choice) =>
          choice.name != PrayerName.sunrise &&
          config.enabledPrayers.contains(choice.name) &&
          choice.time.isAfter(nowLocal),
    );
    PrayerChoice? nextEnabled;
    if (selected != null && !hasFuturePrayer) {
      final tomorrow =
          DateTime(nowLocal.year, nowLocal.month, nowLocal.day + 1);
      final tomorrowPrayers = prayer.today(selected.coordinates, tomorrow);
      for (final choice in tomorrowPrayers) {
        if (choice.name == PrayerName.sunrise) continue;
        if (!config.enabledPrayers.contains(choice.name)) continue;
        if (!choice.time.isAfter(nowLocal)) continue;
        nextEnabled = choice;
        break;
      }
      // A source that returns no rows for a future day still has the
      // nextPrayer contract; use it when that prayer is enabled. This is a
      // defensive path for partial/malformed day data, not the normal one.
      if (nextEnabled == null) {
        final fallback = prayer.nextPrayer(selected.coordinates, nowLocal);
        if (config.enabledPrayers.contains(fallback.name) &&
            fallback.time.isAfter(nowLocal)) {
          nextEnabled = fallback;
        }
      }
    }
    final loc = platformLocalizations();
    // Read inside the existing try: a failed preference read must degrade to
    // "no adhan" (the OS default sound), never fail the whole re-plan.
    final adhanId = await adhanPrefs?.adhanId();
    final fajrAdhanId = await adhanPrefs?.fajrAdhanId();
    final texts = ReminderTexts(
      prayerTitle: (name) => loc.reminderNextPrayer(name.label(loc)),
      prayerSoonTitle: (name, minutes) =>
          loc.reminderAdhanSoon(name.label(loc), minutes.toArabicIndic),
      azkarTitle: loc.reminderAzkar,
      wirdTitle: loc.reminderWird,
    );
    final seed = planReminders(
      now: nowLocal,
      todayPrayers: todayPrayers,
      nextPrayer: nextEnabled,
      prayerEnabled: prayerEnabled,
      enabledPrayers: config.enabledPrayers,
      preAdhanMinutes: config.preAdhanMinutes,
      azkarEnabled: await settings.azkarEnabled(),
      azkarTimeHm: await settings.azkarTimeHm(),
      wirdEnabled: await settings.wirdEnabled(),
      wirdTimeHm: await settings.wirdTimeHm(),
      adhanId: adhanId,
      fajrAdhanId: fajrAdhanId,
      texts: texts,
    );
    // The rest of the window: every enabled prayer still ahead, so the alarms
    // keep coming without the app being opened again.
    DateTime? seedPrayerAt;
    for (final reminder in seed) {
      if (reminder.id == prayerReminderId) seedPrayerAt = reminder.fireAt;
    }
    final horizonDays = <List<PrayerChoice>>[
      todayPrayers,
      if (selected != null)
        for (var offset = 1; offset < reminderHorizonDays; offset++)
          prayer.today(
            selected.coordinates,
            DateTime(nowLocal.year, nowLocal.month, nowLocal.day + offset),
          ),
    ];
    final horizon = planPrayerHorizon(
      now: nowLocal,
      days: horizonDays,
      skipAt: seedPrayerAt,
      enabledPrayers: config.enabledPrayers,
      preAdhanMinutes: config.preAdhanMinutes,
      adhanId: adhanId,
      fajrAdhanId: fajrAdhanId,
      texts: texts,
    );
    final plan = <ScheduledReminder>[...seed, ...horizon];
    await scheduler.scheduleAll(plan);
    return plan;
  } on Object {
    // A failed (re)schedule must never break boot or a screen (W7b v1).
    return const <ScheduledReminder>[];
  }
}
