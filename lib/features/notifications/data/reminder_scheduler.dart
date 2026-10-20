import '../../../core/domain/reminders.dart';

export '../../../core/domain/reminders.dart' show ScheduledReminder;

/// Injectable seam in front of the local-notifications plugin (W7b headless
/// law: the plugin itself is touched by `notifications_binding.dart` only).
/// Implementations must never throw — reminder scheduling is best-effort v1.
abstract interface class ReminderScheduler implements ReminderSchedulerPort {
  /// Requests the OS notification (+ exact-alarm) permissions; false when
  /// refused or unavailable.
  @override
  Future<bool> ensurePermissions();

  /// Replace-all semantics: cancels previously scheduled reminders, then
  /// schedules the given plan.
  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders);
}
