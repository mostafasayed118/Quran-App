import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/update/presentation/update_gate_screen.dart';

import 'support/host.dart';

/// The update gate is the one screen a user cannot leave, so a clipped CTA at a
/// large text scale is a dead end.
///
/// Widths: 360 is the size the owner asked the probe to guard; 320 is the
/// smallest width any existing probe in this repo uses (the adhan picker
/// builds at 320x640). There is **no written product floor** — 320 is a
/// conservative case, and the fix is width-independent, so both are asserted.
///
/// The real Cairo font is loaded because the widget-test font draws every glyph
/// at full em width: with that font this screen "overflows" at any width, and a
/// probe built on it would prove nothing about the shipped app. The
/// `measures the shipped Cairo font` test below fails loudly if the font ever
/// stops loading, so these overflow assertions cannot silently measure the
/// wrong font.
Future<void> _loadCairo() async {
  final loader = FontLoader('Cairo');
  loader.addFont(
    Future.value(
      ByteData.sublistView(
        File('assets/fonts/Cairo-Regular.ttf').readAsBytesSync(),
      ),
    ),
  );
  loader.addFont(
    Future.value(
      ByteData.sublistView(
        File('assets/fonts/Cairo-Bold.ttf').readAsBytesSync(),
      ),
    ),
  );
  await loader.load();
}

Future<void> _pumpAtFloor(
  WidgetTester tester, {
  required bool mandatory,
  double width = 320,
  Future<bool> Function()? onOpenStore,
}) async {
  await _loadCairo();
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    appShell(
      textScale: 2.0,
      home: UpdateGateScreen(
        mandatory: mandatory,
        onOpenStore: onOpenStore ?? () async => true,
        onLater: () async {},
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the probe measures the shipped Cairo font, not the test font', (
    tester,
  ) async {
    await _loadCairo();
    late double glyphWidth;
    await tester.pumpWidget(
      appShell(
        textScale: 2.0,
        home: Builder(
          builder: (context) {
            // The app's own display style: it carries `fontFamily: Cairo`, so this
            // measures the same family the shipped screens use.
            final style = AppTheme.heroTitle.copyWith(fontSize: 44);
            final painter = TextPainter(
              text: TextSpan(text: '٠', style: style),
              textDirection: TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            glyphWidth = painter.width;
            painter.dispose();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      glyphWidth,
      lessThan(40),
      reason:
          'the widget-test font draws this glyph at 88 px; a wider '
          'measurement means Cairo did not resolve, and every overflow '
          'assertion in this file would be testing the wrong font',
    );
  });

  testWidgets('320x640 at textScale 2.0: the mandatory gate fits the screen', (
    tester,
  ) async {
    await _pumpAtFloor(tester, mandatory: true);

    expect(
      tester.takeException(),
      isNull,
      reason: 'the pre-fix column overflows by 40 px with the Cairo font',
    );

    final button = tester.getRect(
      find.widgetWithText(FilledButton, 'حدّث الآن'),
    );
    expect(
      button.bottom,
      lessThanOrEqualTo(640),
      reason: 'the only way out of a mandatory gate must stay on screen',
    );
    expect(
      button.height,
      greaterThanOrEqualTo(48),
      reason: 'house tap-target floor',
    );
  });

  testWidgets(
    '320x640 at textScale 2.0: the copy scrolls, the action still taps',
    (tester) async {
      var opened = 0;
      await _pumpAtFloor(
        tester,
        mandatory: true,
        onOpenStore: () async {
          opened++;
          return true;
        },
      );
      expect(tester.takeException(), isNull);

      // A reader must be able to reach the whole copy and still press the action;
      // geometry alone is not proof of a reachable CTA.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'حدّث الآن'));
      await tester.pump();

      expect(
        opened,
        1,
        reason: 'a pinned action must stay hit-testable while the copy scrolls',
      );
    },
  );

  testWidgets('360x640 at textScale 2.0: both recommended actions reachable', (
    tester,
  ) async {
    await _pumpAtFloor(tester, mandatory: false, width: 360);

    expect(tester.takeException(), isNull);

    final update = tester.getRect(
      find.widgetWithText(FilledButton, 'حدّث الآن'),
    );
    final later = tester.getRect(find.widgetWithText(TextButton, 'لاحقاً'));
    expect(update.bottom, lessThanOrEqualTo(640));
    expect(later.bottom, lessThanOrEqualTo(640));
    expect(update.height, greaterThanOrEqualTo(48));
    expect(later.height, greaterThanOrEqualTo(48));
  });
}
