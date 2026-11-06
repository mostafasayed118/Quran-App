import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/layout/app_breakpoints.dart';
import 'package:quran_yahdi/core/widgets/app_content_frame.dart';
import 'package:quran_yahdi/core/widgets/app_sheet.dart';
import 'package:quran_yahdi/core/widgets/search_field.dart';

void main() {
  testWidgets('below the measure the child is not wrapped', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppContentFrame(
            child: SizedBox(
              key: Key('body'),
              height: 40,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('body'))).width, 360);
  });

  testWidgets('above the measure the body is capped and centred',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppContentFrame(
            child: SizedBox(
              key: Key('body'),
              height: 40,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const Key('body')));
    expect(rect.width, AppBreakpoints.contentMaxWidth);
    expect(rect.center.dx, 600);
  });

  testWidgets('a full-height scroll body keeps filling the height',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppContentFrame(
            child: ListView(
              key: const Key('list'),
              children: const [SizedBox(height: 40)],
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const Key('list')));
    expect(rect.width, AppBreakpoints.contentMaxWidth);
    expect(rect.height, 800);
  });

  testWidgets('a sheet is capped at the sheet measure on a tablet',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showAppSheet<void>(
                  context: context,
                  builder: (_) => const SizedBox(
                    key: Key('sheet-content'),
                    height: 120,
                    width: double.infinity,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('sheet-content'))).width,
      AppBreakpoints.sheetMaxWidth,
    );
  });

  testWidgets('the shared search field follows the ambient direction',
      (tester) async {
    Future<void> pump(TextDirection direction) {
      return tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: SearchField(hint: 'search', onChanged: (_) {}),
          ),
        ),
      ));
    }

    await pump(TextDirection.rtl);
    expect(
      tester.widget<TextField>(find.byType(TextField)).textAlign,
      TextAlign.start,
    );

    await pump(TextDirection.ltr);
    expect(
      tester.widget<TextField>(find.byType(TextField)).textAlign,
      TextAlign.start,
    );
  });
}
