import 'package:flutter/material.dart';

/// Dismissible inline error banner with an optional retry action.
class ErrorStrip extends StatelessWidget {
  const ErrorStrip(
    this.message, {
    super.key,
    this.icon,
    this.onRetry,
    this.actionLabel,
    required this.onDismiss,
    this.dismissTooltip,
  });

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback onDismiss;

  /// W7b (UX-W1 open item): optional wording for the dismiss affordance —
  /// falls back to the generic material close tooltip when null.
  final String? dismissTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = actionLabel;
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        top: false,
        child: ListTile(
          dense: true,
          leading: icon == null ? null : Icon(icon, size: 18),
          title: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onErrorContainer),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null && onRetry != null)
                TextButton(onPressed: onRetry, child: Text(label)),
              IconButton(
                tooltip: dismissTooltip ??
                    MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
