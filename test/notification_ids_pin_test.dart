import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';

void main() {
  test('the reserved notification ids are frozen numerically', () {
    // These ids reach the OS as notification ids; renumbering one silently
    // strands the alarms written by an older build.
    expect(prayerReminderId, 1);
    expect(azkarReminderId, 2);
    expect(wirdReminderId, 3);
    expect(preAdhanReminderId, 4);
  });
}
