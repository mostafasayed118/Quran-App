import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_alphas.dart';
import 'package:quran_yahdi/core/theme/app_colors.dart';

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
}
