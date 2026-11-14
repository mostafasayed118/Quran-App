import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_alphas.dart';
import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/app_icon_size.dart';
import 'package:quran_yahdi/core/theme/app_radius.dart';
import 'package:quran_yahdi/core/theme/app_strokes.dart';
import 'package:quran_yahdi/core/theme/app_type.dart';

/// Pins every token introduced by the W1 wave to the literal it replaced.
///
/// The census in `test/fixtures/design_token_baseline.dart` proves no site was
/// left behind; this test proves the token kept the exact shipped value.
void main() {
  test('splash palette keeps the shipped ARGB values', () {
    expect(AppColors.splashCard, const Color(0xFF042C25));
    expect(AppColors.splashGlowMint, const Color(0xFFA8F3C6));
    expect(AppColors.splashGlowGold, const Color(0xFFFFE088));
    expect(AppColors.splashShadowWarm, const Color(0x6600281A));
    expect(AppColors.splashShadowCool, const Color(0x5922321D));
  });

  test('role alphas keep the shipped values', () {
    expect(AppAlphas.chipTint, 0.10);
    expect(AppAlphas.dividerOnTint, 0.12);
    expect(AppAlphas.outlineFaint, 0.18);
    expect(AppAlphas.secondaryTile, 0.14);
    expect(AppAlphas.errorTint, 0.35);
    expect(AppAlphas.accentRule, 0.35);
    expect(AppAlphas.accentRuleSoft, 0.25);
    expect(AppAlphas.metaInk, 0.70);
    expect(AppAlphas.secondaryInk, 0.75);
    expect(AppAlphas.iconMuted, 0.60);
  });

  test('splash alphas keep the shipped values', () {
    expect(AppColors.splashFooterLight, 0.55);
    expect(AppColors.splashFooterDark, 0.42);
    expect(AppColors.splashCornerLight, 0.10);
    expect(AppColors.splashCornerDark, 0.07);
    expect(AppColors.splashGlowLight, 0.20);
    expect(AppColors.splashGlowDark, 0.13);
    expect(AppColors.splashRing1Light, 0.22);
    expect(AppColors.splashRing1Dark, 0.35);
    expect(AppColors.splashRing2Light, 0.11);
    expect(AppColors.splashRing2Dark, 0.18);
    expect(AppColors.splashAccent, 0.85);
    expect(AppColors.splashCardBorder, 0.16);
  });

  test('type metrics keep the shipped line heights and tracking', () {
    expect(AppType.scriptureHeight, 1.8);
    expect(AppType.scriptureLooseHeight, 1.9);
    expect(AppType.scriptureTightHeight, 1.7);
    expect(AppType.dhikrHeight, 2.1);
    expect(AppType.timerHeight, 1.1);
    expect(AppType.splashWordmarkHeight, 1.2);
    expect(AppType.relaxedHeight, 1.6);
    expect(AppType.quranHeight, 2.0);
    expect(AppType.splashWordmarkTracking, -0.2);
    expect(AppType.splashTaglineTracking, 4.2);
    expect(AppType.splashFooterTracking, 0.3);
    expect(AppType.shareFooterTracking, 0.4);
  });

  test('icon sizes keep the shipped values', () {
    expect(AppIconSize.inline, 13);
    expect(AppIconSize.dot, 14);
    expect(AppIconSize.sm, 16);
    expect(AppIconSize.md, 18);
    expect(AppIconSize.lg, 20);
    expect(AppIconSize.xl, 22);
    expect(AppIconSize.state, 40);
    expect(AppIconSize.hero, 48);
    expect(AppIconSize.dial, 72);
    expect(AppIconSize.gate, 84);
  });

  test('radii and strokes keep the shipped values', () {
    expect(AppRadius.panel, 14);
    expect(AppRadius.dayCell, 10);
    expect(AppRadius.selection, 11);
    expect(AppRadius.sheet, 28);
    expect(AppStrokes.emphasis, 1.4);
    expect(AppStrokes.selection, 1.5);
    expect(AppStrokes.ring, 1.6);
    expect(AppStrokes.accent, 3);
  });
}
