import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../l10n/app_localizations.dart';
import 'hadith_cubit.dart';
import 'hadith_state.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const _HadithTitle()),
      body: BlocBuilder<HadithCubit, HadithState>(
        builder: (context, state) {
          final Widget content = switch (state) {
            HadithLoading() => const LoadingView(),
            HadithFailed() => errorPane(loc),
            final HadithReady ready when ready.items.isEmpty => EmptyState(
                loc.hadithEmpty,
                icon: Icons.menu_book_outlined,
              ),
            final HadithReady ready => Column(
                children: [
                  Expanded(child: _HadithVerses(ready: ready)),
                  _HadithPager(ready: ready),
                ],
              ),
          };
          return content;
        },
      ),
    );
  }
}

class _HadithTitle extends StatelessWidget {
  const _HadithTitle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HadithCubit, HadithState>(
      buildWhen: (a, b) => a is HadithLoading || b is HadithReady,
      builder: (context, state) {
        final s = state;
        final title = s is HadithReady ? s.packTitle : '';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
            if (s is HadithReady && s.language.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                _languageLabel(AppLocalizations.of(context), s.language),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.goldText(context),
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Localized name for a pack language code; anything unknown keeps the raw
/// code (upper-cased, as the chip always rendered it).
String _languageLabel(AppLocalizations loc, String code) {
  return switch (code.toLowerCase()) {
    'ar' => loc.languageArabic,
    'en' => loc.languageEnglish,
    _ => code.toUpperCase(),
  };
}

class _HadithVerses extends StatelessWidget {
  const _HadithVerses({required this.ready});

  final HadithReady ready;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: ready.items.length,
      itemBuilder: (context, index) {
        final (number, text) = ready.items[index];
        final rtl = ready.language == 'ar';
        if (text.isEmpty) {
          return const SizedBox.shrink();
        }
        return _HadithVerseRow(number: number, text: text, rtl: rtl);
      },
    );
  }
}

class _HadithVerseRow extends StatelessWidget {
  const _HadithVerseRow({
    required this.number,
    required this.text,
    required this.rtl,
  });

  final int number;
  final String text;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: direction,
        children: [
          // Fixed 28 dp badge: a FittedBox shrinks the numeral inside the
          // circle at large text scales instead of letting it overflow.
          SizedBox(
            width: 28,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    loc.number(number),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.8),
              textDirection: direction,
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithPager extends StatelessWidget {
  const _HadithPager({required this.ready});

  final HadithReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed:
                  ready.offset > 0 ? context.read<HadithCubit>().prev : null,
              child: Text(loc.hadithPrev),
            ),
            TextButton(
              onPressed:
                  ready.hasMore ? context.read<HadithCubit>().next : null,
              child: Text(loc.hadithNext),
            ),
          ],
        ),
      ),
    );
  }
}
