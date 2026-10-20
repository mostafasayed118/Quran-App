import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hintText = hint;
    final actionLabelText = actionLabel;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (hintText != null) ...[
              const SizedBox(height: 6),
              Text(
                hintText,
                style: AppTheme.mutedFootnote(context),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabelText != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabelText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
