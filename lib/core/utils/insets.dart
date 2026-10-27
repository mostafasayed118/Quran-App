import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Bottom system inset the UI must keep clear right now.
///
/// `MediaQuery.padding.bottom` collapses to zero while the keyboard is open,
/// and `Scaffold` strips it — from `padding` *and* `viewPadding` — for
/// `bottomSheet`/bar slots, so the frame's own `FlutterView` is the source
/// that always survives. While the keyboard is open the Scaffold already
/// resizes for `viewInsets`, so the inset collapses to zero.
///
/// Never call this below a [SafeArea] that already consumed the inset.
double appBottomInset(BuildContext context) {
  final view = View.of(context);
  if (view.viewInsets.bottom > 0) return 0;
  final systemInset = view.viewPadding.bottom / view.devicePixelRatio;
  return math.max(MediaQuery.paddingOf(context).bottom, systemInset);
}

/// [base] with the system bottom inset added — for scrollable bodies.
EdgeInsets appScrollPadding(BuildContext context, EdgeInsets base) {
  return base.copyWith(bottom: base.bottom + appBottomInset(context));
}
