import 'city.dart';
import 'prayer_times.dart';

/// A reminder the planner decided to schedule (plugin-free value type).
class ScheduledReminder {
  /// Creates one plan entry.
  ///
  /// [fireAt] is the absolute instant the reminder fires at; the platform
  /// maps it to the exact-alarm time.
  const ScheduledReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    this.body,
    this.payload,
  });

  /// The platform alarm id — stable per reminder, so a re-plan replaces the
  /// same alarm instead of piling up duplicates.
  final int id;

  /// The absolute instant the reminder fires at (the platform maps it to
  /// the exact-alarm time).
  final DateTime fireAt;

  /// The notification title shown in the shade.
  final String title;

  /// Optional second line; null keeps the shade title-only (no duplicate
  /// copy — audit §1.22).
  final String? body;

  /// Tap-routing tag (planner payload constants); null = plain tap.
  final String? payload;
}

/// Fallback azkar time when `azkar_reminder_time` is unset or malformed.
const String defaultAzkarTimeHm = '06:30';

/// Fallback wird time when `wird_reminder_time` is unset or malformed.
const String defaultWirdTimeHm = '20:00';

/// Cross-feature seam in front of the local-notifications plugin (the plugin
/// itself is touched by `notifications_binding.dart` only). Implementations
/// must never throw — reminder scheduling is best-effort v1.
abstract interface class ReminderSchedulerPort {
  /// Requests the OS notification (+ exact-alarm) permissions; false when
  /// refused or unavailable.
  ///
  /// A request made before the plugin is ready is queued (not refused) and
  /// reported as granted — the implementation performs it as soon as the
  /// plugin is ready.
  Future<bool> ensurePermissions();

  /// Replace-all semantics: cancels previously scheduled reminders, then
  /// schedules the given plan.
  Future<void> scheduleAll(List<ScheduledReminder> reminders);
}

/// Cross-feature seam for the shared reminder (re)planning path: the
/// notification engine lives in the notifications feature, every consumer
/// (settings screen, prayer-times screen) reaches it through this port.
abstract interface class ReminderRescheduler {
  /// (Re)plans the reminders for [city]/[prayer] and hands the plan to
  /// [scheduler]. Best-effort by design — never throws.
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  });
}

/// Cross-feature seam for the reminder settings storage. It also carries the
/// shared [ReminderRescheduler] path, so a screen that owns the settings can
/// re-plan without importing the notifications feature.
abstract interface class ReminderSettingsPort implements ReminderRescheduler {
  /// Whether the azkar reminders are enabled.
  Future<bool> azkarEnabled();

  /// The azkar reminder time as an 'HH:mm' string; null when unset (the
  /// planner then falls back to [defaultAzkarTimeHm]).
  Future<String?> azkarTimeHm();

  /// Whether the wird reminders are enabled.
  Future<bool> wirdEnabled();

  /// The wird reminder time as an 'HH:mm' string; null when unset (the
  /// planner then falls back to [defaultWirdTimeHm]).
  Future<String?> wirdTimeHm();

  /// Persists the azkar reminders on/off state.
  Future<void> setAzkarEnabled(bool enabled);

  /// Persists the azkar reminder time as an 'HH:mm' string.
  Future<void> setAzkarTime(String hm);

  /// Persists the wird reminders on/off state.
  Future<void> setWirdEnabled(bool enabled);

  /// Persists the wird reminder time as an 'HH:mm' string.
  Future<void> setWirdTime(String hm);
}
