/// A reminder the planner decided to schedule (plugin-free value type).
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final DateTime fireAt;
  final String title;
  final String body;

  /// Tap-routing tag (planner payload constants); null = plain tap.
  final String? payload;
}

/// Injectable seam in front of the local-notifications plugin (W7b headless
/// law: the plugin itself is touched by `notifications_binding.dart` only).
/// Implementations must never throw — reminder scheduling is best-effort v1.
abstract interface class ReminderScheduler {
  /// Requests the OS notification (+ exact-alarm) permissions; false when
  /// refused or unavailable.
  Future<bool> ensurePermissions();

  /// Replace-all semantics: cancels previously scheduled reminders, then
  /// schedules the given plan.
  Future<void> scheduleAll(List<ScheduledReminder> reminders);
}
