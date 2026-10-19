import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/main.dart' as app;

/// Boots the real app (one `app.main()` per test process) and waits — bounded —
/// for the home feature grid to render.
Future<void> bootApp(WidgetTester tester) async {
  await app.main();
  await waitFor(
    tester,
    find.text('القرآن الكريم'),
    timeout: const Duration(seconds: 30),
  );
}

/// Bounded pump loop until [finder] matches; fails on timeout. House rule:
/// no bare `pumpAndSettle` — drift streams keep the scheduler busy.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for $finder');
    }
    await tester.pump(step);
  }
}
