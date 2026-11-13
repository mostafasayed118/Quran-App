import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/widgets/loading_and_error_views.dart';

import 'support/host.dart';

void main() {
  Future<void> pump(WidgetTester tester) =>
      tester.pumpWidget(appShell(home: const Scaffold(body: LoadingView())));

  testWidgets('a load that finishes at once never paints the ring',
      (tester) async {
    await pump(tester);

    // Present in the tree, so every test and every screen reader still finds
    // the loading state — it is the paint that is held back.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_opacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 140));
    expect(_opacity(tester), 0, reason: 'the hold phase must stay invisible');
  });

  testWidgets('a slow load fades the ring in instead of popping it',
      (tester) async {
    await pump(tester);

    await tester.pump(const Duration(milliseconds: 220));
    final mid = _opacity(tester);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));

    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacity(tester), 1);
  });
}

double _opacity(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.byType(CircularProgressIndicator),
    matching: find.byType(Opacity),
  );
  return tester.widget<Opacity>(finder.first).opacity;
}
