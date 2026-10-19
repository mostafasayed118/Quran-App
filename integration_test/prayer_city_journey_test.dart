import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_harness.dart';

// Arabic UI copy pinned from lib/l10n/app_ar.arb and the prayer surface.
const String prayerTile = 'مواقيت الصلاة';
const String fajrLabel = 'فجر';
const String selectCity = 'اختر مدينتك';
const String cityQuery = 'الإسكندرية';
const String cityName = 'الإسكندرية';
const String homeQuranTile = 'القرآن الكريم';

/// Bounded pump loop until any of [finders] matches; fails on timeout.
Future<void> _waitForAny(WidgetTester tester, List<Finder> finders) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!finders.any((Finder finder) => finder.evaluate().isNotEmpty)) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for any of: $finders');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Bounded wait until [finder] is gone — used to let the push transition
/// finish (the home route goes offstage, so its tiles stop false-matching
/// labels this test probes for).
Future<void> _waitUntilGone(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for $finder to go away');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'pick Alexandria offline from the city picker and see it on the times screen',
    (tester) async {
      await bootApp(tester);

      // Home → «مواقيت الصلاة» tile.
      await tester.tap(find.text(prayerTile));
      await _waitUntilGone(tester, find.text(homeQuranTile));

      // Screen settles in either form: a city is already set (prayer rows
      // including «فجر») or no city yet (empty state + pick-city action).
      await _waitForAny(tester, [
        find.text(fajrLabel),
        find.text(selectCity),
      ]);

      // Open the city picker via whichever affordance this device shows:
      // the city card's edit icon (city set) or the empty-state button.
      final editButton = find.byTooltip(selectCity);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
      } else {
        await tester.tap(find.text(selectCity).first);
      }

      // City picker → search «الإسكندرية» → select the result (bundled
      // cities, fully offline).
      await waitFor(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField), cityQuery);
      await tester.pump(const Duration(milliseconds: 300));
      final alexandriaTile = find.widgetWithText(ListTile, cityName);
      await waitFor(tester, alexandriaTile);
      await tester.ensureVisible(alexandriaTile.first);
      await tester.tap(alexandriaTile.first);

      // Back on the times screen: the persisted city and a prayer label show.
      await waitFor(tester, find.text(fajrLabel));
      await waitFor(tester, find.text(cityName));
      expect(find.text(cityName), findsWidgets);
    },
  );
}
