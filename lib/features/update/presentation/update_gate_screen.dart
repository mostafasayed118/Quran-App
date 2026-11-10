import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/app_localizations.dart';

/// Opens the platform's store listing; returns true when it was accepted.
/// Required so the screen never imports the app composition root — the router
/// wires the gateway (see `lib/features/update/data/version_ack_store.dart`).
typedef OpenStoreListing = Future<bool> Function();

/// The update gate screen.
///
/// Shown at `/update` when the version gate has a verdict to surface:
/// - **update required** (mandatory): a blocking full-screen surface — no
///   dismissal, no bypass, no close button. An old install that would break
///   against the current backend must not keep the app running.
/// - **update recommended**: a non-blocking prompt pushed by the boot glue;
///   it offers "Later" instead of a dead end.
///
/// [mandatory] and [onLater] are resolved by the router at build time from
/// the gate — the screen itself only renders and dispatches, so it stays a
/// leaf widget with no DI and no app-layer import.
///
/// Both modes open the official Play listing via [onOpenStore]. The store
/// decides whether an update dialog (or store page) appears; this widget
/// never fakes it. A failing store surface shows a toast instead of a
/// dead-end button.
class UpdateGateScreen extends StatelessWidget {
  const UpdateGateScreen({
    super.key,
    required this.mandatory,
    required this.onOpenStore,
    this.onLater,
  });

  final bool mandatory;

  /// Asks the platform to open the store listing.
  final OpenStoreListing onOpenStore;

  /// Dismisses the optional-update prompt. Null for the mandatory surface;
  /// the router wires the ack write when the prompt is shown.
  final Future<void> Function()? onLater;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final body = mandatory ? loc.updateRequiredBody : loc.updateRecommendedBody;
    final title =
        mandatory ? loc.updateRequiredTitle : loc.updateRecommendedTitle;
    return PopScope(
      canPop: !mandatory,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !mandatory,
          title: Text(title),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 84,
                  color: AppTheme.goldText(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openStore(context),
                    child: Text(loc.updateNow),
                  ),
                ),
                if (!mandatory)
                  TextButton(
                    onPressed: () => _dismissRecommended(context),
                    child: Text(loc.updateLater),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await onOpenStore();
    if (opened || !context.mounted) return;
    AppToast.showOn(
      messenger,
      AppLocalizations.of(context).updateUnavailable,
      tone: ToastTone.error,
    );
  }

  Future<void> _dismissRecommended(BuildContext context) async {
    final dismiss = onLater;
    if (dismiss != null) unawaited(dismiss());
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
