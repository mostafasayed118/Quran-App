import 'package:quran_yahdi/core/domain/reminders.dart';

/// Records every scheduled plan and lets a test choose the permission verdict.
///
/// Lives here rather than beside its first user: eleven test files need it, and
/// importing one test file from another pulled that file's whole suite along.
class FakeReminderScheduler implements ReminderSchedulerPort {
  final plans = <List<ScheduledReminder>>[];
  bool permissionsResult = true;
  int permissionCalls = 0;
  int scheduleCalls = 0;

  @override
  Future<bool> ensurePermissions() async {
    permissionCalls++;
    return permissionsResult;
  }

  @override
  Future<bool> ensureExactAlarms() async => true;

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {
    scheduleCalls++;
    plans.add(reminders);
  }
}
