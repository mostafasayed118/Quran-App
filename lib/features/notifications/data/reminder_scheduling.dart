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
Future<void> scheduleReminders({
  required CitySource city,
  required PrayerTimesPort prayer,
  required ReminderSettingsPort settings,
  required ReminderSchedulerPort scheduler,
  bool prayerEnabled = true,
  PrayerConfig config = PrayerConfig.egyptian,
  DateTime? now,
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
      // Keep the historical seam for sources that only implement nextPrayer
      // for the day boundary (the frozen fake does): if the tomorrow list
      // yields nothing, use the port's next prayer when it is enabled.
      if (nextEnabled == null) {
        final fallback = prayer.nextPrayer(selected.coordinates, nowLocal);
        if (config.enabledPrayers.contains(fallback.name) &&
            fallback.time.isAfter(nowLocal)) {
          nextEnabled = fallback;
        }
      }
    }
    final loc = platformLocalizations();
    final plan = planReminders(
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
      texts: ReminderTexts(
        prayerTitle: (name) => loc.reminderNextPrayer(name.label(loc)),
        prayerSoonTitle: (name, minutes) =>
            loc.reminderAdhanSoon(name.label(loc), minutes.toArabicIndic),
        azkarTitle: loc.reminderAzkar,
        wirdTitle: loc.reminderWird,
      ),
    );
    await scheduler.scheduleAll(plan);
  } on Object {
    // A failed (re)schedule must never break boot or a screen (W7b v1).
  }
}
