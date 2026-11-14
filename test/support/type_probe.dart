import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'host.dart';

/// Pumps [child] at an exact logical width and text scale through the shared
/// harness, so a probe measures the app's own theme rather than a raw
/// MaterialApp.
Future<void> pumpTypeProbe(
  WidgetTester tester, {
  required Widget child,
  required double width,
  double height = 800,
  double textScale = 1.0,
  Locale locale = const Locale('ar'),
}) async {
  tester.view.physicalSize = Size(width, height) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    appShell(
      home: Scaffold(body: child),
      locale: locale,
      textScale: textScale,
    ),
  );
  await tester.pump();
}

/// No `RenderFlex` overflow was recorded for the frame under test.
void expectNoOverflow(WidgetTester tester) =>
    expect(tester.takeException(), isNull);

/// The paragraph did not lose text to an ellipsis. An ellipsis throws no
/// exception, so this is the only way to catch a silently truncated label.
void expectNotTruncated(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isFalse);
}

/// Every matched box clears the 48 × 48 touch target.
void expectTapTargets(WidgetTester tester, Finder finder) {
  for (final element in finder.evaluate()) {
    final box = element.renderObject! as RenderBox;
    expect(box.size.shortestSide, greaterThanOrEqualTo(48),
        reason: element.widget.runtimeType.toString());
  }
}
