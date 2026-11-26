import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/pager_icons.dart';

import 'support/host.dart';

/// H1 (audit round 2): proves the RENDERED chevron direction, not the IconData.
///
/// Flutter marks `chevron_left` / `chevron_right` with
/// `matchTextDirection: true` and wraps them in a
/// `Transform(scale(-1, 1, 1))` in RTL, so the icon data alone does not
/// describe what the user sees. These assertions read the matrix that actually
/// wraps the rendered icon, and count the wrappers so an unrelated Transform
/// cannot produce a false pass.
///
/// The app therefore returns the logical chevron in every locale and lets the
/// framework mirror it; a second manual flip would invert the direction.
void main() {
  Future<void> pumpIcon(WidgetTester tester, IconData icon, Locale locale) {
    return pumpAppHost(
      tester,
      home: Center(child: Icon(icon)),
      locale: locale,
    );
  }

  Finder transformsUnderIcon() =>
      find.descendant(of: find.byType(Icon), matching: find.byType(Transform));

  /// The glyph's own orientation, XOR the framework mirroring.
  bool rendersLeft(WidgetTester tester, IconData icon) {
    final mirrored = transformsUnderIcon().evaluate().length == 1;
    final pointsLeftUnmirrored = icon == Icons.chevron_left;
    return pointsLeftUnmirrored != mirrored;
  }

  testWidgets('chevron_right in RTL is mirrored by exactly one Transform', (
    tester,
  ) async {
    await pumpIcon(tester, Icons.chevron_right, const Locale('ar'));
    expect(transformsUnderIcon(), findsOneWidget);
    expect(
      tester.widget<Transform>(transformsUnderIcon()).transform.storage[0],
      -1.0,
    );
  });

  testWidgets('chevron_right in LTR is not wrapped in a Transform', (
    tester,
  ) async {
    await pumpIcon(tester, Icons.chevron_right, const Locale('en'));
    expect(transformsUnderIcon(), findsNothing);
  });

  testWidgets('chevron_left in RTL is mirrored by exactly one Transform', (
    tester,
  ) async {
    await pumpIcon(tester, Icons.chevron_left, const Locale('ar'));
    expect(transformsUnderIcon(), findsOneWidget);
    expect(
      tester.widget<Transform>(transformsUnderIcon()).transform.storage[0],
      -1.0,
    );
  });

  testWidgets('chevron_left in LTR is not wrapped in a Transform', (
    tester,
  ) async {
    await pumpIcon(tester, Icons.chevron_left, const Locale('en'));
    expect(transformsUnderIcon(), findsNothing);
  });

  test('the pager helper returns the logical chevron', () {
    expect(pagerChevronFor(next: true), Icons.chevron_right);
    expect(pagerChevronFor(next: false), Icons.chevron_left);
  });

  testWidgets('the next pager chevron renders pointing left in RTL', (
    tester,
  ) async {
    final icon = pagerChevronFor(next: true);
    await pumpIcon(tester, icon, const Locale('ar'));
    expect(
      rendersLeft(tester, icon),
      isTrue,
      reason: 'next must render pointing left in RTL (forward direction)',
    );
  });

  testWidgets('the previous pager chevron renders pointing right in RTL', (
    tester,
  ) async {
    final icon = pagerChevronFor(next: false);
    await pumpIcon(tester, icon, const Locale('ar'));
    expect(
      rendersLeft(tester, icon),
      isFalse,
      reason: 'previous must render pointing right in RTL (backward direction)',
    );
  });
}
