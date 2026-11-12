import 'package:flutter/material.dart';

import 'state_message.dart';

/// Centered progress indicator for a route-level load.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
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
