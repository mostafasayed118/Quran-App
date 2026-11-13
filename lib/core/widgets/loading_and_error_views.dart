import 'package:flutter/material.dart';

import 'state_message.dart';

/// Centered progress indicator for a route-level load.
///
/// The ring holds invisible for the first 160 ms of a 320 ms implicit fade.
/// On this app the data behind a route is a local database or a bundled asset,
/// so most loads finish inside a frame or two; painting the ring immediately
/// turned those into a flicker. A slow load still gets a visible indicator — it
/// fades in instead of popping. Keeping it an implicit animation (rather than a
/// timer that reveals it) means there is nothing to cancel, the indicator stays
/// in the tree for tests, and a load that completes early simply never paints.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  /// Total length of the implicit fade; the first half is the invisible hold.
  static const Duration _fade = Duration(milliseconds: 320);
  static const Interval _hold = Interval(0.5, 1, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: _fade,
        curve: _hold,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// Centered failure message with an optional recovery action.
///
/// A failure with no way out is a dead end: the screen stays broken until the
/// user leaves the route or restarts the app. Callers that can retry pass
/// [onRetry] and get a labeled button; [retryLabel] is already-localized copy.
class ErrorView extends StatelessWidget {
  const ErrorView(
    this.message, {
    super.key,
    this.onRetry,
    this.retryLabel,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final canRetry = onRetry != null && retryLabel != null;
    return StateMessage(
      message: message,
      icon: icon ?? Icons.cloud_off_outlined,
      actionLabel: canRetry ? retryLabel : null,
      onAction: canRetry ? onRetry : null,
    );
  }
}
