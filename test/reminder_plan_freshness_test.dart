import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/reminder_plan_freshness.dart';

void main() {
  test('the same day in the same zone needs no re-plan', () {
    final freshness = ReminderPlanFreshness(now: DateTime(2026, 11, 4, 9));

    expect(freshness.needsReplan(DateTime(2026, 11, 4, 23, 59)), isFalse);
  });

  test('crossing midnight needs a re-plan', () {
    final freshness = ReminderPlanFreshness(now: DateTime(2026, 11, 4, 23, 55));

    expect(freshness.needsReplan(DateTime(2026, 11, 5, 0, 1)), isTrue);
  });

  test('a new time zone needs a re-plan even on the same day', () {
    final freshness = ReminderPlanFreshness(
      now: DateTime(2026, 11, 4, 9),
      utcOffsetMinutes: 120,
    );

    expect(
      freshness.needsReplan(DateTime(2026, 11, 4, 9), utcOffsetMinutes: 60),
      isTrue,
      reason: 'every fire instant moves with the zone',
    );
    expect(
      freshness.needsReplan(DateTime(2026, 11, 4, 9), utcOffsetMinutes: 120),
      isFalse,
    );
  });

  test('marking the new instant clears the staleness', () {
    final freshness = ReminderPlanFreshness(now: DateTime(2026, 11, 4, 9));
    final nextDay = DateTime(2026, 11, 5, 9);

    expect(freshness.needsReplan(nextDay), isTrue);
    freshness.mark(nextDay);
    expect(freshness.needsReplan(nextDay), isFalse);
  });

  test('a plan built just before midnight is stale a minute later', () {
    final freshness =
        ReminderPlanFreshness(now: DateTime(2026, 12, 31, 23, 59));

    expect(freshness.needsReplan(DateTime(2027, 1, 1, 0, 0, 30)), isTrue);
  });
}
