import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
