import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/reciter_pack.dart';

/// Browsing surface for the curated reciter packs.
///
/// The page publishes the five selection criteria (decision 2026-11-02, D2) so
/// any list on it is auditable, and lists the packs that passed
/// [validateReciterPack] — a pack without a named human reviewer stays
/// invisible here even if someone hands it to the constructor.
///
/// v1 ships with [kReciterPacks] empty; [packs] is a parameter so tests can
/// inject signed and unsigned packs without touching the const list.
class ReciterPacksScreen extends StatelessWidget {
  const ReciterPacksScreen({super.key, this.packs = kReciterPacks});

  final List<ReciterPack> packs;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    // The gate, not the caller, decides what is published: an unsigned pack is
    // dropped here even when it is handed to the constructor.
    final published =
        packs.where((pack) => validateReciterPack(pack).isEmpty).toList();
    // The five published criteria, in the order the decision states them.
    final criteria = <String>[
      loc.reciterPacksCriterion1,
      loc.reciterPacksCriterion2,
      loc.reciterPacksCriterion3,
      loc.reciterPacksCriterion4,
      loc.reciterPacksCriterion5,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(loc.reciterPacksTitle)),
      body: AppContentFrame(
        child: ListView(
          key: const Key('reciterPacksList'),
          padding: appScrollPadding(
            context,
            const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(loc.reciterPacksIntro, style: AppTheme.bodyText),
            ),
            SectionHeader(
              title: loc.reciterPacksCriteriaTitle,
              inset: AppSpacing.lg,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final criterion in criteria) _Bullet(text: criterion),
                ],
              ),
            ),
            if (published.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: EmptyState(
                  loc.reciterPacksEmpty,
                  icon: Icons.collections_bookmark_outlined,
                ),
              )
            else
              for (final pack in published) _PackCard(pack: pack),
          ],
        ),
      ),
    );
  }
}

/// One bulleted line: a dot in the start margin, the copy in the rest of the
/// row so it wraps to as many lines as the text scale needs.
class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decoration only: screen readers must read the line, not «•».
          ExcludeSemantics(
            child: Text(
              '•',
              style: AppTheme.bodyText.copyWith(color: colors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTheme.bodyText)),
        ],
      ),
    );
  }
}

/// One published pack: what it is, why each entry is in it, and who attested.
class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack});

  final ReciterPack pack;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pack.titleAr, style: AppTheme.cardTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              pack.descriptionAr,
              style: AppTheme.bodyText.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final entry in pack.entries) _Bullet(text: entry.reasonAr),
            Text(
              loc.reciterPacksReviewer(pack.reviewedBy),
              style: AppTheme.caption.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
