import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Centered empty-state message with an optional icon and action button.
class EmptyState extends StatelessWidget {
  const EmptyState(
    this.message, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final colors = Theme.of(context).colorScheme;
    return Center(
      // Scrollable so a 2.0 text scale on a short window cannot overflow.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 40, color: colors.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(color: colors.onSurface),
            ),
            if (label != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
