import 'package:flutter/material.dart';

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
          Expanded(
            child: Text(
              title,
              style: AppTheme.sectionLabel.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
