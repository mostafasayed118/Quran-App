import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart'
    show dateOnly;

import 'reminder_scheduler.dart';

/// Fixed notification ids (also the dedupe key of the replace-all plan).
const int prayerReminderId = 1;
const int azkarReminderId = 2;

/// Fallback azkar time when `azkar_reminder_time` is unset or malformed.
const String defaultAzkarTimeHm = '06:30';

const (int, int) _defaultAzkarTime = (6, 30);

/// Localized title/body inputs, composed by the caller at SCHEDULE time
/// (fire-time localization is impossible once the app is dead — disclosed v1
/// limitation). Plain strings keep the planner pure and testable.
class ReminderTexts {
  const ReminderTexts({
    required this.prayerTitle,
    required this.azkarTitle,
    required this.azkarBody,
  });

  final String Function(PrayerName prayer) prayerTitle;
  final String azkarTitle;
  final String azkarBody;
}

/// Pure scheduling policy (PM ruling, keep it dumb): the next prayer still
/// ahead today + the daily azkar at its settings time (today if still ahead,
/// else tomorrow). Missed-while-dead reminders are accepted v1 and are not
/// back-filled; the app re-plans on every open and on every city change.
List<ScheduledReminder> planReminders({
  required DateTime now,
  required List<PrayerChoice> todayPrayers,
  required bool azkarEnabled,
  required String? azkarTimeHm,
  required ReminderTexts texts,
}) {
  final byId = <int, ScheduledReminder>{};

  for (final choice in todayPrayers) {
    if (choice.name == PrayerName.sunrise) continue;
    if (!choice.time.isAfter(now)) continue;
    final title = texts.prayerTitle(choice.name);
    byId[prayerReminderId] = ScheduledReminder(
      id: prayerReminderId,
      fireAt: choice.time,
      title: title,
      body: title,
    );
    break;
  }

  if (azkarEnabled) {
    final time = _parseHm(azkarTimeHm) ?? _defaultAzkarTime;
    final day = dateOnly(now);
    var fireAt = DateTime(day.year, day.month, day.day, time.$1, time.$2);
    if (!fireAt.isAfter(now)) {
      fireAt = DateTime(day.year, day.month, day.day + 1, time.$1, time.$2);
    }
    byId[azkarReminderId] = ScheduledReminder(
      id: azkarReminderId,
      fireAt: fireAt,
      title: texts.azkarTitle,
      body: texts.azkarBody,
    );
  }

  return List.unmodifiable(byId.values);
}

/// Parses 'H:mm'/'HH:mm' 24-hour input; null on anything malformed.
(int, int)? _parseHm(String? hm) {
  if (hm == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hm.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return (hour, minute);
}
