import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_system_ui.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';

void main() {
  test('light theme: transparent bars, dark icons', () {
    final style = AppSystemUi.overlayStyle(Brightness.light);
    expect(style.statusBarColor, Colors.transparent);
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.systemNavigationBarDividerColor, Colors.transparent);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });

  test('dark theme: transparent bars, light icons', () {
    final style = AppSystemUi.overlayStyle(Brightness.dark);
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });

  test('both app themes carry the style on the AppBar', () {
    expect(
      AppTheme.light.appBarTheme.systemOverlayStyle
          ?.systemNavigationBarIconBrightness,
      Brightness.dark,
    );
    expect(
      AppTheme.dark.appBarTheme.systemOverlayStyle
          ?.systemNavigationBarIconBrightness,
      Brightness.light,
    );
  });
}
