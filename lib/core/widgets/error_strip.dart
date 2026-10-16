import 'package:flutter/material.dart';

class ErrorStrip extends StatelessWidget {
  const ErrorStrip(
    this.message, {
    super.key,
    this.icon,
    this.onRetry,
    this.actionLabel,
    required this.onDismiss,
  });

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
              if (actionLabel != null && onRetry != null)
                TextButton(onPressed: onRetry, child: Text(actionLabel!)),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
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
