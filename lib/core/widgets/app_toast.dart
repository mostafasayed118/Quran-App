import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// The three intents a confirmation toast can carry.
enum ToastTone {
  /// The action completed (copied, saved, exported).
  success,

  /// The action failed, or the input cannot be honoured.
  error,

  /// Neutral acknowledgement (a setting changed, a target was applied).
  info,
}

/// Brand-consistent transient confirmations.
///
/// Built on [SnackBar] on purpose: the app already reaches its toasts through
/// `ScaffoldMessenger` (including tests that look for `SnackBar`), and Material
/// supplies the live-region announcement, swipe-to-dismiss and the queue. This
/// class only supplies the look — surface-coloured card, tone icon, hairline —
/// and the policy: a new toast replaces the visible one instead of stacking.
abstract final class AppToast {
  /// Long enough to read one line twice; failures get an extra second.
  static const Duration _confirmation = Duration(seconds: 3);
  static const Duration _failure = Duration(seconds: 4);

  /// Toasts never stretch across a tablet: past this the line length makes a
  /// confirmation harder to scan than a narrow one.
  static const double _maxWidth = 520;

  static void show(
    BuildContext context,
    String message, {
    ToastTone tone = ToastTone.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    showOn(
      messenger,
      message,
      tone: tone,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// The post-`await` form: capture the messenger before suspending, then
  /// present without touching a possibly-unmounted [BuildContext].
  static void showOn(
    ScaffoldMessengerState messenger,
    String message, {
    ToastTone tone = ToastTone.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    if (!messenger.mounted) return;
    final context = messenger.context;
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = _accentOf(context, tone);
    final width = math.min(
      MediaQuery.sizeOf(context).width - AppSpacing.lg * 2,
      _maxWidth,
    );

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: _ToastBody(
            message: message,
            tone: tone,
            icon: icon,
            accent: accent,
          ),
          // A fixed width keeps the toast a card on every form factor; the
          // Scaffold still lifts it above the navigation bar and mini player.
          width: width > 0 ? width : null,
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.surface,
          elevation: 3,
          margin: width > 0 ? null : const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(
              color: isLight ? AppColors.hairline : AppColors.darkHairline,
            ),
          ),
          dismissDirection: DismissDirection.down,
          duration:
              duration ?? (tone == ToastTone.error ? _failure : _confirmation),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: accent,
                  onPressed: onAction,
                ),
        ),
      );
  }

  /// The tone's foreground, resolved for the current surface.
  ///
  /// Gold is a light accent (~1.9:1 on paper), so [ToastTone.info] uses the
  /// darkened `goldText` in light mode and the bright gold in dark mode.
  static Color _accentOf(BuildContext context, ToastTone tone) =>
      switch (tone) {
        ToastTone.success => Theme.of(context).colorScheme.primary,
        ToastTone.error => Theme.of(context).colorScheme.error,
        ToastTone.info => AppTheme.goldText(context),
      };
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.message,
    required this.tone,
    required this.icon,
    required this.accent,
  });

  final String message;
  final ToastTone tone;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        // The glyph restates the tone; screen readers already get the message
        // and should not hear a second, decorative label.
        ExcludeSemantics(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: AppColors.badgeTintAlpha),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? _defaultIcon,
              size: 18,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  // Arabic script needs the extra leading; 1.45 clips the
                  // diacritics on a two-line message.
                  height: 1.6,
                ),
          ),
        ),
      ],
    );
  }

  IconData get _defaultIcon => switch (tone) {
        ToastTone.success => Icons.check_circle_outline,
        ToastTone.error => Icons.error_outline,
        ToastTone.info => Icons.info_outline,
      };
}
