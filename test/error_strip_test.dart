import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/widgets/error_strip.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  testWidgets('retry action fires and dismiss fires on close', (tester) async {
    var retries = 0;
    var dismissed = false;
    await pump(
      tester,
      ErrorStrip(
        'تعذّر التنزيل',
        actionLabel: 'أعِد المحاولة',
        onRetry: () => retries++,
        onDismiss: () => dismissed = true,
      ),
    );
    await tester.tap(find.text('أعِد المحاولة'));
    await tester.tap(find.byIcon(Icons.close));
    expect(retries, 1);
    expect(dismissed, isTrue);
    expect(find.text('تعذّر التنزيل'), findsOneWidget);
  });

  testWidgets('icon shows when passed; no retry button without an action label',
      (tester) async {
    await pump(
      tester,
      ErrorStrip(
        'فشل الشبكة',
        icon: Icons.wifi_off,
        onDismiss: () {},
      ),
    );
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
