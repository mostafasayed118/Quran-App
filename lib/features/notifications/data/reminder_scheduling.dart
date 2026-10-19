import 'dart:ui' show Locale;

import 'package:quran_yahdi/core/l10n/prayer_names.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'reminder_planner.dart';
import 'reminder_scheduler.dart';
import 'reminder_settings.dart';

/// Shared (re)schedule path for boot, the prayer-times cubit and the settings
/// cubit: reads the persisted city + reminder settings, composes the plan with
/// the app's pinned AR strings and hands it to the scheduler. Best-effort by
/// design — never throws (W7b v1).
Future<void> scheduleReminders({
  required CityRepository city,
  required PrayerTimeService prayer,
  required ReminderSettings settings,
  required ReminderScheduler scheduler,
  DateTime? now,
}) async {
  try {
    final selected = await city.selectedCity();
    final nowLocal = now ?? DateTime.now();
    final plan = <ScheduledReminder>[];
    if (selected != null) {
      final loc = lookupAppLocalizations(const Locale('ar'));
      plan.addAll(planReminders(
        now: nowLocal,
        todayPrayers: prayer.today(selected.coordinates, nowLocal),
        azkarEnabled: await settings.azkarEnabled(),
        azkarTimeHm: await settings.azkarTimeHm(),
        wirdEnabled: await settings.wirdEnabled(),
        wirdTimeHm: await settings.wirdTimeHm(),
        texts: ReminderTexts(
          prayerTitle: (name) => loc.reminderNextPrayer(name.label(loc)),
          azkarTitle: loc.reminderAzkar,
          wirdTitle: loc.reminderWird,
        ),
      ));
    }
    await scheduler.scheduleAll(plan);
  } on Object {
    // A failed (re)schedule must never break boot or a screen (W7b v1).
  }
}
