import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/widgets/ar_badge.dart';
import 'package:quran_yahdi/core/widgets/download_progress.dart';
import 'package:quran_yahdi/core/widgets/empty_state.dart';
import 'package:quran_yahdi/core/widgets/search_field.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  testWidgets('ArabicBadge renders the coin with primary ring styling',
      (tester) async {
    await pump(tester, const ArabicBadge('٣'));
    expect(find.text('٣'), findsOneWidget);
    final box = tester.widget<Container>(
        find.ancestor(of: find.text('٣'), matching: find.byType(Container)));
    expect(box.constraints?.maxWidth, 38);
  });

  testWidgets('SearchField emits onChanged and shows the arrow hint',
      (tester) async {
    var query = '';
    await pump(
        tester,
        SearchField(
          hint: 'ابحث…',
          onChanged: (q) => query = q,
        ));
    await tester.enterText(find.byType(TextField), 'عفاسي');
    expect(query, 'عفاسي');
    expect(find.text('ابحث…'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('SearchField honors a provided controller', (tester) async {
    final controller = TextEditingController(text: 'الفاتحة');
    addTearDown(controller.dispose);
    await pump(
        tester,
        SearchField(
          hint: 'ابحث…',
          onChanged: (_) {},
          controller: controller,
        ));
    expect(find.text('الفاتحة'), findsOneWidget);
  });

  testWidgets('EmptyState shows message alone without action', (tester) async {
    await pump(tester, const EmptyState('لا توجد مدينة بعد'));
    expect(find.text('لا توجد مدينة بعد'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('DownloadProgressLabel defaults format and indicator value',
      (tester) async {
    await pump(tester, const DownloadProgressLabel(received: 50, total: 100));
    expect(find.text('50/100'), findsOneWidget);
    final progress = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progress.value, 0.5);
  });

  testWidgets('DownloadProgressLabel formats via callback and clamps',
      (tester) async {
    await pump(
        tester,
        DownloadProgressLabel(
          received: 9999,
          total: 100,
          width: 96,
          format: (r, t) => '$r bytes',
        ));
    expect(find.text('9999 bytes'), findsOneWidget);
    final progress = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progress.value, 1.0);
  });
}
