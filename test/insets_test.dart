import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/insets.dart';

const double kHeight = 800;
const double kInset = 48;

void setInset(WidgetTester tester, {double inset = kInset}) {
  tester.view.physicalSize = const Size(400, kHeight);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: inset);
  tester.view.viewPadding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('body padding: the bottom inset is the nav bar height',
      (tester) async {
    setInset(tester);
    late double measured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        measured = appBottomInset(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(measured, kInset);
  });

  testWidgets('keyboard open: the inset collapses', (tester) async {
    setInset(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    late double measured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        measured = appBottomInset(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(measured, 0);
  });

  testWidgets('bar stripped of padding: falls back to viewPadding',
      (tester) async {
    setInset(tester);
    late double measured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomSheet: Builder(builder: (context) {
          measured = appBottomInset(context);
          return const SizedBox(height: 10);
        }),
      ),
    ));
    expect(measured, kInset);
  });

  testWidgets('adds the inset to a scroll padding', (tester) async {
    setInset(tester);
    late EdgeInsets measured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        measured = appScrollPadding(context, const EdgeInsets.all(12));
        return const SizedBox.shrink();
      }),
    ));
    expect(measured, const EdgeInsets.fromLTRB(12, 12, 12, 60));
  });

  testWidgets('last list row stays above the nav bar', (tester) async {
    setInset(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ListView(
            padding: appScrollPadding(context, const EdgeInsets.all(12)),
            children: [
              for (var i = 0; i < 20; i++) const SizedBox(height: 80),
              Container(key: const Key('last'), height: 80),
            ],
          ),
        ),
      ),
    ));
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(const Key('last')));
    expect(rect.bottom, lessThanOrEqualTo(kHeight - kInset));
  });
}
