import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/widgets/empty_state.dart';
import 'package:quran_yahdi/core/widgets/loading_and_error_views.dart';

import 'support/host.dart';

void main() {
  testWidgets('a failure without a retry stays a message', (tester) async {
    await pumpAppHost(tester, home: const ErrorView('تعذّر التحميل'));

    expect(find.text('تعذّر التحميل'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('a failure with a retry offers the action and calls it',
      (tester) async {
    var retried = 0;
    await pumpAppHost(
      tester,
      home: Scaffold(
        body: ErrorView(
          'تعذّر التحميل',
          onRetry: () => retried++,
          retryLabel: 'أعِد المحاولة',
        ),
      ),
    );

    await tester.tap(find.text('أعِد المحاولة'));
    await tester.pump();

    expect(retried, 1);
  });

  testWidgets('an empty state takes an icon and keeps its action',
      (tester) async {
    var tapped = 0;
    await pumpAppHost(
      tester,
      home: Scaffold(
        body: EmptyState(
          'لا نتائج',
          icon: Icons.search_off,
          actionLabel: 'ابحث',
          onAction: () => tapped++,
        ),
      ),
    );

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    await tester.tap(find.text('ابحث'));
    await tester.pump();
    expect(tapped, 1);
  });
}
