import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Shows the shared delete-confirmation dialog and returns true when the
/// user confirms. Used by the library pack list and the per-surah downloads
/// list (previously duplicated AlertDialogs).
Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final loc = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(loc.libraryDelete),
        ),
      ],
    ),
  );
  return confirmed == true;
}
