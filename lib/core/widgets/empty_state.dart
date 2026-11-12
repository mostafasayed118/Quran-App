import 'package:flutter/material.dart';

import 'state_message.dart';

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
    return StateMessage(
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
