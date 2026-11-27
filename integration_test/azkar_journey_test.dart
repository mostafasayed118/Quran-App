import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_harness.dart';

// Arabic UI copy pinned from lib/l10n/app_ar.arb, assets/data/azkar.json
// («أذكار الصباح»: 13 items; the first has count = 1) and the azkar surface.
const String azkarTile = 'الأذكار';
const String morningCollection = 'أذكار الصباح';
const String firstCounter = '١';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the first morning-zikr counter advances on tap and resolves when done',
    (tester) async {
      await bootApp(tester);

      // Home → «الأذكار» tile → collections list.
      await tester.tap(find.text(azkarTile));
      await waitFor(tester, find.text(morningCollection));

      // Collections → «أذكار الصباح» → reciting list.
      await tester.tap(find.text(morningCollection));

      // The reciting list renders one Card per zikr. Wait for the list itself
      // before pinning its first card: a `.first` finder handed to the wait
      // loop throws `Bad state: No element` while no Card is onstage (the
      // route/state transition after the collection tap).
      final anyCounter = find.descendant(
        of: find.byType(Card),
        matching: find.text(firstCounter),
      );
      await waitFor(tester, anyCounter);

      final firstCard = find.byType(Card).first;
      final counterOne = find.descendant(
        of: firstCard,
        matching: find.text(firstCounter),
      );
      expect(counterOne, findsOneWidget);

      // Tap the first counter target: the zikr completes (remaining 1 → 0)
      // and the counter display flips to the screen's done check.
      await tester.tap(counterOne);
      final anyDone = find.descendant(
        of: find.byType(Card),
        matching: find.byIcon(Icons.check),
      );
      await waitFor(tester, anyDone);

      final doneCheck = find.descendant(
        of: firstCard,
        matching: find.byIcon(Icons.check),
      );
      expect(doneCheck, findsOneWidget);
    },
  );
}
