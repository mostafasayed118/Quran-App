import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';

void main() {
  test('the clear set covers every follow-up the planner can write', () {
    final ids = reminderAlarmIds();
    final day = DateTime.utc(2026, 11, 16);

    for (var i = 0; i < kFajrFollowUpMinutes.length; i++) {
      expect(
        ids,
        contains(fajrFollowUpAlarmId(day, i)),
        reason:
            'a new follow-up in kFajrFollowUpMinutes must be cancellable '
            'by the next plan change; the set used to hard-code two',
      );
    }
  });
}
