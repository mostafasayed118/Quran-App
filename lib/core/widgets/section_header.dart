import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Small start-aligned title above a group.
///
/// A group of 14 equally-weighted tiles tells the eye nothing; a labeled group
/// does. The accent bar carries the hierarchy without a second accent colour.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.inset = AppSpacing.md,
  });

  final String title;
  final Widget? trailing;

  /// Horizontal inset applied here. Pass 0 when the parent list already pads
  /// its rows, so the label lines up with the row content instead of the
  /// screen edge.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ruleColor = Theme.of(context).brightness == Brightness.light
        ? AppColors.hairline
        : AppColors.darkHairline;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        inset,
        AppSpacing.lg,
        inset,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: AppRadius.smAll,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              title,
              style: AppTheme.sectionLabel.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          // The rule carries the section to the end of its row. A labelled
          // group that stops mid-air reads as a stray caption; a ruled one
          // reads as a page division — the same reason the app uses hairlines
          // instead of a second surface tone.
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(height: 1, color: ruleColor),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
