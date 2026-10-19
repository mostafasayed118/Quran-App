import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_harness.dart';

// Arabic UI copy pinned from lib/l10n/app_ar.arb and the reader surface.
const String quranTile = 'القرآن الكريم';
const String surahFatiha = 'الفاتحة';
const String bookmarkSave = 'احفظ الآية';
const String bookmarkRemove = 'أزل الحفظ';

bool _isBookmarkToggle(Widget widget) =>
    widget is IconButton &&
    (widget.tooltip == bookmarkSave || widget.tooltip == bookmarkRemove);

final Finder _bookmarkToggles = find.byWidgetPredicate(_isBookmarkToggle);

/// Tooltip of the first (topmost, i.e. first-ayah) bookmark toggle, or null
/// when no toggle is currently built.
String? _firstToggleTooltip() {
  final elements = _bookmarkToggles.evaluate();
  if (elements.isEmpty) return null;
  return (elements.first.widget as IconButton).tooltip;
}

/// Bounded wait until the topmost toggle flips away from [before].
Future<void> _waitForToggleFlip(WidgetTester tester, String before) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (true) {
    final tip = _firstToggleTooltip();
    if (tip != null && tip != before) return;
    if (DateTime.now().isAfter(deadline)) {
      fail('bookmark toggle did not flip away from "$before"');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Bounded wait until [finder] is gone (a popped route has left the stage).
Future<void> _waitUntilGone(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for $finder to go away');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'open Al-Fatiha, toggle the first ayah bookmark, reopen, state persisted',
    (tester) async {
      await bootApp(tester);

      // Home → Quran feature tile → surah index.
      await tester.tap(find.text(quranTile));
      await waitFor(tester, find.text(surahFatiha));

      // Index → «الفاتحة» → reader (defaults to the verses list).
      await tester.tap(find.text(surahFatiha));
      await waitFor(tester, _bookmarkToggles);

      final before = _firstToggleTooltip();
      if (before == null) fail('no bookmark toggle rendered on the first ayah');

      // Toggle the first ayah's bookmark; the DB write round-trips through
      // the bookmarks stream and flips the icon + tooltip.
      await tester.tap(_bookmarkToggles.first);
      await _waitForToggleFlip(tester, before);
      final after = _firstToggleTooltip();
      if (after == null) fail('bookmark toggle vanished after the tap');
      expect(after, isNot(before));

      // Back to the index, then reopen the surah (fresh cubit + DB read).
      await tester.tap(find.byType(BackButton));
      await _waitUntilGone(tester, _bookmarkToggles);
      await waitFor(tester, find.text(surahFatiha));
      await tester.tap(find.text(surahFatiha));
      await waitFor(tester, _bookmarkToggles);

      // Persistence proof: the first ayah's toggle survived the round-trip.
      expect(_firstToggleTooltip(), after);
    },
  );
}
