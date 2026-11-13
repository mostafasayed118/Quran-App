import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/next_prayer_focus.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/features/prayer/presentation/countdown/next_prayer_countdown_screen.dart';

import 'support/host.dart';

final _clock = RegExp(r'^[٠-٩]{2}:[٠-٩]{2}:[٠-٩]{2}$');

void main() {
  testWidgets('the focus view shows the prayer, the city and one digit per box',
      (tester) async {
    final target =
        DateTime.now().add(const Duration(hours: 2, minutes: 5, seconds: 4));
    await tester.pumpWidget(appShell(
      home: NextPrayerCountdownScreen(
        focus: NextPrayerFocus(
          prayer: PrayerName.fajr,
          time: target,
          cityName: 'القاهرة',
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('فجر'), findsOneWidget);
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);

    // The clock is composed from one box per digit, so it is announced as one
    // string rather than eight glyphs — and that string is still HH:MM:SS.
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(_clock), findsOneWidget,
        reason: 'the countdown reads as one clock, in the shared format');
    semantics.dispose();
  });

  testWidgets(
      'without a payload the screen explains and still offers the times',
      (tester) async {
    await tester.pumpWidget(appShell(home: const NextPrayerCountdownScreen()));
    await tester.pump();

    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(_clock), findsNothing);
    semantics.dispose();
  });
}
