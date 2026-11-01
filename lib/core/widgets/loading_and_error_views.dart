import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

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
    final colors = Theme.of(context).colorScheme;
    final canRetry = onRetry != null && retryLabel != null;
    return Center(
      // Scrollable so a 2.0 text scale on a short window cannot overflow.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.cloud_off_outlined,
              size: 40,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(color: colors.onSurface),
            ),
            if (canRetry) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onRetry, child: Text(retryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
