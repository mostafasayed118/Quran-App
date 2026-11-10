import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/core/utils/date_only.dart';
import 'package:quran_yahdi/core/utils/hour_minute.dart';

// Compat: existing importers of this file keep resolving the fallback times.
export 'package:quran_yahdi/core/domain/reminders.dart'
    show defaultAzkarTimeHm, defaultWirdTimeHm;

/// Fixed notification ids (also the dedupe key of the replace-all plan).
const int prayerReminderId = 1;
const int azkarReminderId = 2;
const int wirdReminderId = 3;

/// Optional early reminder for the chosen prayer; only present when the user
/// sets a pre-adhan lead time. Kept above the frozen 1/2/3 ids.
const int preAdhanReminderId = 4;

/// How many days of prayer alarms one plan pre-registers, today included.
///
/// The app re-plans on boot, on every prayer-tab load, on a settings or city
/// change and on a day change while it is alive. One alarm per prayer is not
/// enough: a week is what keeps the reminders ringing for a user who does not
/// open the app every day, and it stays far below Android's per-app alarm cap.
const int reminderHorizonDays = 7;

/// The five reminded prayers, in calendar order.
///
/// Sunrise is a time marker, never a reminder, so it has no alarm slot.
const List<PrayerName> _remindedPrayers = <PrayerName>[
  PrayerName.fajr,
  PrayerName.dhuhr,
  PrayerName.asr,
  PrayerName.maghrib,
  PrayerName.isha,
];

/// Reserved id blocks for the rolling horizon (the frozen 1-4 stay untouched).
const int _horizonPrayerBase = 1000;
const int _horizonPreAdhanBase = 2000;

/// The day's slot inside the horizon window.
///
/// Slots are reused as the window rolls, which is what makes the id set
/// bounded: [reminderAlarmIds] can clear EVERY alarm the planner can ever
/// write without remembering the previous plan (the app may have been killed
/// since the last one).
int _horizonSlot(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay %
    reminderHorizonDays;

/// The alarm id of [name] on [day] inside the rolling horizon.
int prayerAlarmId(DateTime day, PrayerName name) {
  assert(name != PrayerName.sunrise, 'sunrise is a marker, never a reminder');
  return _horizonPrayerBase +
      _horizonSlot(day) * 10 +
      _remindedPrayers.indexOf(name);
}

/// The pre-adhan alarm id of [name] on [day] inside the rolling horizon.
int preAdhanAlarmId(DateTime day, PrayerName name) {
  assert(name != PrayerName.sunrise, 'sunrise is a marker, never a reminder');
  return _horizonPreAdhanBase +
      _horizonSlot(day) * 10 +
      _remindedPrayers.indexOf(name);
}

/// Reserved id block for the optional Fajr follow-up nudges.
const int _horizonFajrFollowUpBase = 3000;

/// The [index]-th follow-up of Fajr on [day]: 0 = +5 min, 1 = +10 min.
int fajrFollowUpAlarmId(DateTime day, int index) {
  assert(index >= 0 && index < 2, 'the Fajr follow-up is two nudges');
  return _horizonFajrFollowUpBase + _horizonSlot(day) * 10 + index;
}

/// Every alarm id this planner can write.
///
/// A plan change clears all of them before scheduling: the binding keeps no
/// memory across a process death, so a reminder the user turned off in an
/// earlier session would otherwise keep firing for the rest of the window.
Set<int> reminderAlarmIds() => <int>{
      prayerReminderId,
      azkarReminderId,
      wirdReminderId,
      preAdhanReminderId,
      for (var slot = 0; slot < reminderHorizonDays; slot++)
        for (var i = 0; i < _remindedPrayers.length; i++) ...<int>[
          _horizonPrayerBase + slot * 10 + i,
          _horizonPreAdhanBase + slot * 10 + i,
        ],
      for (var slot = 0; slot < reminderHorizonDays; slot++)
        for (var i = 0; i < 2; i++) _horizonFajrFollowUpBase + slot * 10 + i,
    };

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
    this.prayerSoonTitle,
    this.azkarBody,
    this.wirdTitle,
    this.wirdBody,
    this.fajrFollowUpTitle,
  });

  /// Title builder for a prayer reminder.
  final String Function(PrayerName prayer) prayerTitle;

  /// Optional title builder for the pre-adhan reminder; null skips it.
  final String Function(PrayerName prayer, int minutes)? prayerSoonTitle;

  /// Title of the azkar reminder.
  final String azkarTitle;

  /// Optional shade body for the azkar reminder; null keeps it title-only.
  final String? azkarBody;

  /// Wird reminder copy; the reminder is skipped while this title is null.
  final String? wirdTitle;

  /// Optional shade body for the wird reminder; null keeps it title-only.
  final String? wirdBody;

  /// Optional Fajr follow-up title; null skips the two nudges.
  final String? fajrFollowUpTitle;
}

/// Pure scheduling policy (PM ruling, keep it dumb): the next prayer still
/// ahead today, else the supplied `nextPrayer` (tomorrow's Fajr), + the daily
/// azkar and wird at their settings times (today if still ahead, else
/// tomorrow). Missed-while-dead reminders are accepted v1 and are not
/// back-filled; the app re-plans on every open and on every city change.
///
/// This is the SEED of the plan. [planPrayerHorizon] adds the rest of the
/// window on top of it (one alarm per prayer is not enough when the app stays
/// closed for a day).
List<ScheduledReminder> planReminders({
  required DateTime now,
  required List<PrayerChoice> todayPrayers,
  PrayerChoice? nextPrayer,
  bool prayerEnabled = true,
  Set<PrayerName> enabledPrayers = PrayerConfig.defaultEnabledPrayers,
  int preAdhanMinutes = 0,
  required bool azkarEnabled,
  required String? azkarTimeHm,
  bool wirdEnabled = false,
  String? wirdTimeHm,
  required ReminderTexts texts,
  String? adhanId,
  String? fajrAdhanId,
}) {
  final byId = <int, ScheduledReminder>{};

  if (prayerEnabled) {
    PrayerChoice? chosen;
    for (final choice in todayPrayers) {
      if (choice.name == PrayerName.sunrise) continue;
      if (!enabledPrayers.contains(choice.name)) continue;
      if (!choice.time.isAfter(now)) continue;
      chosen = choice;
      break;
    }
    if (chosen == null &&
        nextPrayer != null &&
        nextPrayer.time.isAfter(now) &&
        enabledPrayers.contains(nextPrayer.name)) {
      chosen = nextPrayer;
    }
    if (chosen != null) {
      byId[prayerReminderId] = ScheduledReminder(
        id: prayerReminderId,
        fireAt: chosen.time,
        title: texts.prayerTitle(chosen.name),
        payload: prayerReminderPayload,
        // Null when no adhan is configured: that keeps today's behaviour
        // (legacy channel, OS default sound).
        adhanId: adhanId == null
            ? null
            : adhanIdForPrayer(
                prayer: chosen.name,
                globalId: adhanId,
                fajrId: fajrAdhanId,
              ),
      );
      final soonTitle = texts.prayerSoonTitle;
      if (preAdhanMinutes > 0 && soonTitle != null) {
        final fireAt = chosen.time.subtract(Duration(minutes: preAdhanMinutes));
        if (fireAt.isAfter(now)) {
          byId[preAdhanReminderId] = ScheduledReminder(
            id: preAdhanReminderId,
            fireAt: fireAt,
            title: soonTitle(chosen.name, preAdhanMinutes),
            payload: prayerReminderPayload,
          );
        }
      }
    }
  }

  if (azkarEnabled) {
    byId[azkarReminderId] = ScheduledReminder(
      id: azkarReminderId,
      fireAt: _nextFireAt(now, azkarTimeHm, _defaultAzkarTime),
      title: texts.azkarTitle,
      body: texts.azkarBody,
      payload: azkarReminderPayload,
      repeatsDaily: true,
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
      repeatsDaily: true,
    );
  }

  return List.unmodifiable(byId.values);
}

/// The prayer reminders BEYOND the single next prayer [planReminders] emits.
///
/// [days] is today and the following days (`days[0]` is today). Every enabled
/// prayer still ahead is scheduled with a horizon id, so the alarms keep firing
/// while the app stays closed. [skipAt] is the instant the seed reminder
/// already covers — scheduling it twice would notify twice.
///
/// When [ReminderTexts.fajrFollowUpTitle] is non-null, two bounded follow-up
/// nudges are added at +5 and +10 minutes after each Fajr; they use the OS
/// default sound (the 25 s adhan clip is not replayed) and the same prayer
/// tap payload.
List<ScheduledReminder> planPrayerHorizon({
  required DateTime now,
  required List<List<PrayerChoice>> days,
  DateTime? skipAt,
  bool prayerEnabled = true,
  Set<PrayerName> enabledPrayers = PrayerConfig.defaultEnabledPrayers,
  int preAdhanMinutes = 0,
  required ReminderTexts texts,
  String? adhanId,
  String? fajrAdhanId,
}) {
  if (!prayerEnabled) return const <ScheduledReminder>[];
  final out = <ScheduledReminder>[];
  for (final dayPrayers in days) {
    for (final choice in dayPrayers) {
      if (choice.name == PrayerName.sunrise) continue;
      if (!enabledPrayers.contains(choice.name)) continue;
      // The follow-ups are independent of the prayer alarm: a Fajr that just
      // passed can still have a +10 nudge ahead.
      final followUpTitle = texts.fajrFollowUpTitle;
      if (followUpTitle != null && choice.name == PrayerName.fajr) {
        for (var i = 0; i < 2; i++) {
          final fireAt = choice.time.add(Duration(minutes: 5 * (i + 1)));
          if (!fireAt.isAfter(now)) continue;
          out.add(
            ScheduledReminder(
              id: fajrFollowUpAlarmId(choice.time, i),
              fireAt: fireAt,
              title: followUpTitle,
              payload: prayerReminderPayload,
            ),
          );
        }
      }
      if (!choice.time.isAfter(now)) continue;
      if (skipAt != null && choice.time.isAtSameMomentAs(skipAt)) continue;
      out.add(
        ScheduledReminder(
          id: prayerAlarmId(choice.time, choice.name),
          fireAt: choice.time,
          title: texts.prayerTitle(choice.name),
          payload: prayerReminderPayload,
          adhanId: adhanId == null
              ? null
              : adhanIdForPrayer(
                  prayer: choice.name,
                  globalId: adhanId,
                  fajrId: fajrAdhanId,
                ),
        ),
      );
      final soonTitle = texts.prayerSoonTitle;
      if (preAdhanMinutes > 0 && soonTitle != null) {
        final fireAt = choice.time.subtract(Duration(minutes: preAdhanMinutes));
        if (fireAt.isAfter(now)) {
          out.add(
            ScheduledReminder(
              id: preAdhanAlarmId(choice.time, choice.name),
              fireAt: fireAt,
              title: soonTitle(choice.name, preAdhanMinutes),
              payload: prayerReminderPayload,
            ),
          );
        }
      }
    }
  }
  return List.unmodifiable(out);
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
  final time = parseHourMinute(hm) ?? fallback;
  final day = dateOnly(now);
  final fireAt = DateTime(day.year, day.month, day.day, time.$1, time.$2);
  if (fireAt.isAfter(now)) return fireAt;
  return DateTime(day.year, day.month, day.day + 1, time.$1, time.$2);
}
