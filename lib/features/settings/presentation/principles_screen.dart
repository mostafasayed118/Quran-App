import 'package:flutter/material.dart';

import '../../../core/widgets/app_content_frame.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/insets.dart';
import '../../../l10n/app_localizations.dart';

/// What the app promises the reader: free without ads, no account, recitations
/// credited to their reciters, and no retroactive paywall.
///
/// Static copy only — no state, no dependency, nothing to load (R10). The four
/// blocks are the owner-approved sentences, rendered verbatim.
class PrinciplesScreen extends StatelessWidget {
  const PrinciplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.principlesTitle)),
      body: AppContentFrame(
        child: ListView(
          padding: appScrollPadding(
            context,
            const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          children: [
            _PrincipleTile(
              icon: Icons.money_off_outlined,
              text: loc.principlesFree,
            ),
            _PrincipleTile(
              icon: Icons.lock_outline,
              text: loc.principlesNoAccount,
            ),
            _PrincipleTile(
              icon: Icons.record_voice_over_outlined,
              text: loc.principlesAttribution,
            ),
            _PrincipleTile(
              icon: Icons.handshake_outlined,
              text: loc.principlesFuturePaid,
            ),
          ],
        ),
      ),
    );
  }
}

/// One principle: a leading glyph and its sentence.
///
/// The glyph sits in the start margin and the sentence takes the rest of the
/// row, so the copy wraps to as many lines as the text scale needs instead of
/// being squeezed into a fixed-height tile.
class _PrincipleTile extends StatelessWidget {
  const _PrincipleTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTheme.bodyText)),
        ],
      ),
    );
  }
}
