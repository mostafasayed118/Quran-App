import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/asma_repository.dart';
import 'asma_cubit.dart';
import 'asma_state.dart';

const TextStyle _gridNameArStyle = TextStyle(
  fontFamily: QuranFonts.meQuran,
  fontSize: 22,
);

const TextStyle _sheetNameArStyle = TextStyle(
  fontFamily: QuranFonts.meQuran,
  fontSize: 40,
);

const TextStyle _sheetMeaningArStyle = TextStyle(
  fontFamily: QuranFonts.meQuran,
  fontSize: 16,
  height: 1.7,
);

TextStyle _sheetNameEnStyle(ColorScheme colors) => TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: colors.primary,
    );

class AsmaScreen extends StatelessWidget {
  const AsmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.asmaUlHusna)),
      body: BlocBuilder<AsmaCubit, AsmaState>(
        builder: (context, state) => switch (state) {
          AsmaLoading() => const LoadingView(),
          AsmaFailed() => errorPane(loc),
          AsmaReady(:final names) when names.isEmpty =>
            EmptyState(loc.noResults),
          AsmaReady(:final names, :final selected) => Stack(
              children: [
                _NamesGrid(names: names),
                if (selected != null) ...[
                  const Positioned.fill(child: _Scrim()),
                  _NameSheet(name: selected),
                ],
              ],
            ),
        },
      ),
    );
  }
}

class _NameSheet extends StatelessWidget {
  const _NameSheet({required this.name});

  final AsmaName name;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Card(
        margin: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + appBottomInset(context),
        ),
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        loc.namePosition(name.n.toArabicIndic),
                        style: AppTheme.mutedAt(colors, 12),
                      ),
                    ),
                    IconButton(
                      tooltip: loc.clearSelection,
                      icon: const Icon(Icons.close),
                      onPressed: () => context.read<AsmaCubit>().select(null),
                    ),
                  ],
                ),
                Text(
                  name.nameAr,
                  textAlign: TextAlign.center,
                  style: _sheetNameArStyle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  name.nameEn,
                  textAlign: TextAlign.center,
                  style: _sheetNameEnStyle(colors),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  name.meaningAr,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: _sheetMeaningArStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  name.meaningEn,
                  textAlign: TextAlign.center,
                  style: AppTheme.mutedAt(colors, 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NamesGrid extends StatelessWidget {
  const _NamesGrid({required this.names});

  final List<AsmaName> names;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: appScrollPadding(context, const EdgeInsets.all(AppSpacing.md)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemCount: names.length,
      itemBuilder: (context, i) => _NameCell(name: names[i]),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.name});

  final AsmaName name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.read<AsmaCubit>().select(name),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest
              .withValues(alpha: AppColors.mutedSurfaceAlpha),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name.n.toArabicIndic,
              style: AppTheme.mutedAt(colors, 10),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name.nameAr,
                textAlign: TextAlign.center,
                style: _gridNameArStyle,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                name.nameEn,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.mutedFootnote(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.read<AsmaCubit>().select(null),
        child: ColoredBox(
          color: Theme.of(context)
              .colorScheme
              .scrim
              .withValues(alpha: AppColors.scrimAlpha),
        ),
      ),
    );
  }
}
