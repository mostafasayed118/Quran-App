import 'package:flutter/services.dart';

/// System-bar chrome for a forced edge-to-edge Android window.
///
/// Android 15+/targetSdk 35+ draws the bars over the app and ignores the bar
/// colors, so the only levers left are the icon brightness and transparent
/// bar backgrounds (the app content itself paints the strip).
abstract final class AppSystemUi {
  static const Color _transparent = Color(0x00000000);

  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final iconBrightness = isLight ? Brightness.dark : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: _transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: brightness,
      systemNavigationBarColor: _transparent,
      systemNavigationBarDividerColor: _transparent,
      systemNavigationBarIconBrightness: iconBrightness,
    );
  }
}
