import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Shared centered state message: an optional icon, one message and an
/// optional action.
///
/// Both [EmptyState] and [ErrorView] are this shape; keeping the layout in one
/// widget means a spacing or text-scale fix lands in both. The scroll view is
/// deliberate: a 2.0 text scale on a short window must not overflow.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = actionLabel;
    final action = onAction;
    return Center(
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
            if (label != null && action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: action, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
