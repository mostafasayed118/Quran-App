import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/utils/date_only.dart';

import 'reminder_scheduler.dart';

// Compat: existing importers of this file keep resolving the fallback times.
export 'package:quran_yahdi/core/domain/reminders.dart'
    show defaultAzkarTimeHm, defaultWirdTimeHm;

/// Fixed notification ids (also the dedupe key of the replace-all plan).
const int prayerReminderId = 1;
const int azkarReminderId = 2;
const int wirdReminderId = 3;

/// Tap payloads: cold/warm notification taps carry these tags so the app
/// layer can route to the reminder's own screen (W7b non-goal closed).
const String prayerReminderPayload = 'prayer';
const String azkarReminderPayload = 'azkar';
const String wirdReminderPayload = 'wird';

const (int, int) _defaultAzkarTime = (6, 30);
const (int, int) _defaultWirdTime = (20, 0);

/// Localized title/body inputs, composed by the caller at SCHEDULE time
/// (fire-time localization is impossible once the app is dead — disclosed v1
/// limitation). Plain strings keep the planner pure and testable.
class ReminderTexts {
  /// Localizable texts used by the reminder notifications.
  const ReminderTexts({
    required this.prayerTitle,
    required this.azkarTitle,
    this.azkarBody,
    this.wirdTitle,
    this.wirdBody,
  });

  /// Title builder for a prayer reminder.
  final String Function(PrayerName prayer) prayerTitle;

  /// Title of the azkar reminder.
  final String azkarTitle;

  /// Optional shade body for the azkar reminder; null keeps it title-only.
  final String? azkarBody;

  /// Wird reminder copy; the reminder is skipped while this title is null.
  final String? wirdTitle;

  /// Optional shade body for the wird reminder; null keeps it title-only.
  final String? wirdBody;
}

/// Pure scheduling policy (PM ruling, keep it dumb): the next prayer still
/// ahead today, else the supplied `nextPrayer` (tomorrow's Fajr), + the daily
/// azkar and wird at their settings times (today if still ahead, else
/// tomorrow). Missed-while-dead reminders are accepted v1 and are not
/// back-filled; the app re-plans on every open and on every city change.
List<ScheduledReminder> planReminders({
  required DateTime now,
  required List<PrayerChoice> todayPrayers,
  PrayerChoice? nextPrayer,
  bool prayerEnabled = true,
  required bool azkarEnabled,
  required String? azkarTimeHm,
  bool wirdEnabled = false,
  String? wirdTimeHm,
  required ReminderTexts texts,
}) {
  final byId = <int, ScheduledReminder>{};

  if (prayerEnabled) {
    var prayerPlanned = false;
    for (final choice in todayPrayers) {
      if (choice.name == PrayerName.sunrise) continue;
      if (!choice.time.isAfter(now)) continue;
      byId[prayerReminderId] = ScheduledReminder(
        id: prayerReminderId,
        fireAt: choice.time,
        title: texts.prayerTitle(choice.name),
        payload: prayerReminderPayload,
      );
      prayerPlanned = true;
      break;
    }
    if (!prayerPlanned && nextPrayer != null && nextPrayer.time.isAfter(now)) {
      byId[prayerReminderId] = ScheduledReminder(
        id: prayerReminderId,
        fireAt: nextPrayer.time,
        title: texts.prayerTitle(nextPrayer.name),
        payload: prayerReminderPayload,
      );
    }
  }

  if (azkarEnabled) {
    byId[azkarReminderId] = ScheduledReminder(
      id: azkarReminderId,
      fireAt: _nextFireAt(now, azkarTimeHm, _defaultAzkarTime),
      title: texts.azkarTitle,
      body: texts.azkarBody,
      payload: azkarReminderPayload,
    );
  }

  final wirdTitle = texts.wirdTitle;
  if (wirdEnabled && wirdTitle != null) {
    byId[wirdReminderId] = ScheduledReminder(
      id: wirdReminderId,
      fireAt: _nextFireAt(now, wirdTimeHm, _defaultWirdTime),
      title: wirdTitle,
      body: texts.wirdBody,
      payload: wirdReminderPayload,
    );
  }

  return List.unmodifiable(byId.values);
}

/// First-boot POST_NOTIFICATIONS grace (UX-FIX 2): ask only for a user who
/// wants reminders and whose notifications are currently disabled. A granted
/// OS (true) or an unknown state (null) stays silent — never re-prompt.
bool shouldRequestBootPermission({
  required bool? notificationsEnabled,
  required bool azkarEnabled,
}) =>
    azkarEnabled && notificationsEnabled == false;

/// Today at the 'H:mm' settings time when still ahead, else tomorrow at it;
/// [fallback] covers unset or malformed values (azkar and wird share it).
DateTime _nextFireAt(DateTime now, String? hm, (int, int) fallback) {
  final time = _parseHm(hm) ?? fallback;
  final day = dateOnly(now);
  final fireAt = DateTime(day.year, day.month, day.day, time.$1, time.$2);
  if (fireAt.isAfter(now)) return fireAt;
  return DateTime(day.year, day.month, day.day + 1, time.$1, time.$2);
}

/// Parses 'H:mm'/'HH:mm' 24-hour input; null on anything malformed.
(int, int)? _parseHm(String? hm) {
  if (hm == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hm.trim());
  if (match == null) return null;
  final hourText = match.group(1);
  final minuteText = match.group(2);
  if (hourText == null || minuteText == null) return null;
  final hour = int.parse(hourText);
  final minute = int.parse(minuteText);
  if (hour > 23 || minute > 59) return null;
  return (hour, minute);
}
