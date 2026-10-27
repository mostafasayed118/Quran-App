import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'duas_cubit.dart';
import 'duas_state.dart';

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.duasAndRuqyah)),
      body: BlocBuilder<DuasCubit, DuasState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 10, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<DuasTab>(
                      segments: [
                        ButtonSegment(
                          value: DuasTab.duas,
                          label: Text(loc.duasTab),
                          icon: const Icon(Icons.volunteer_activism),
                        ),
                        ButtonSegment(
                          value: DuasTab.ruqyah,
                          label: Text(loc.ruqyahTab),
                          icon: const Icon(Icons.healing),
                        ),
                      ],
                      selected: {
                        state is RuqyahInView ||
                                (state is DuasFailed &&
                                    state.tab == DuasTab.ruqyah)
                            ? DuasTab.ruqyah
                            : DuasTab.duas,
                      },
                      onSelectionChanged: (selection) =>
                          context.read<DuasCubit>().selectTab(selection.first),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                DuasLoading() => const LoadingView(),
                DuasFailed() => errorPane(loc),
                DuasInView() => const _DuasView(),
                RuqyahInView() => const _RuqyahView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DuasView extends StatelessWidget {
  const _DuasView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuasCubit, DuasState>(
      builder: (context, state) {
        final view = state as DuasInView;
        if (view.entries.isEmpty) {
          return EmptyState(AppLocalizations.of(context).noResults);
        }
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  for (final category in view.categories)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: view.selectedCategory == category,
                        onSelected: (_) =>
                            context.read<DuasCubit>().selectCategory(
                                  view.selectedCategory == category
                                      ? null
                                      : category,
                                ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: appScrollPadding(
                  context,
                  const EdgeInsets.all(AppSpacing.md),
                ),
                itemCount: view.entries.length,
                itemBuilder: (context, i) {
                  final entry = view.entries[i];
                  return DuaCard(
                    text: entry.text,
                    fontFamily: QuranFonts.meQuran,
                    fontSize: 17,
                    height: 1.8,
                    count: entry.count,
                    reference: entry.reference,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RuqyahView extends StatelessWidget {
  const _RuqyahView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuasCubit, DuasState>(
      builder: (context, state) {
        final loc = AppLocalizations.of(context);
        final view = state as RuqyahInView;
        if (view.entries.isEmpty) {
          return EmptyState(loc.noResults);
        }
        return ListView.builder(
          padding: appScrollPadding(
            context,
            const EdgeInsets.all(AppSpacing.md),
          ),
          itemCount: view.entries.length,
          itemBuilder: (context, i) {
            final entry = view.entries[i];
            final citation = entry.citation;
            return DuaCard(
              text: entry.displayText,
              fontFamily: entry.isQuran ? QuranFonts.quran : QuranFonts.meQuran,
              fontSize: entry.isQuran ? 18 : 17,
              height: entry.isQuran ? 2.0 : 1.8,
              citation: citation == null ? null : loc.ornateBrackets(citation),
              count: entry.count,
              reference: entry.reference,
            );
          },
        );
      },
    );
  }
}

class DuaCard extends StatelessWidget {
  const DuaCard({
    super.key,
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.height,
    this.citation,
    this.count,
    this.reference,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final double height;
  final String? citation;
  final int? count;
  final String? reference;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final citationText = citation;
    final repeatCount = count;
    final referenceText = reference;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (citationText != null)
              Text(
                citationText,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.secondary,
                ),
              ),
            Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                height: height,
              ),
            ),
            if (repeatCount != null && repeatCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  loc.duaRepeat(repeatCount.toArabicIndic),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            if (referenceText != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  referenceText,
                  textAlign: TextAlign.right,
                  style: AppTheme.mutedFootnote(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
