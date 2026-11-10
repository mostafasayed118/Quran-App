import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'hadith_cubit.dart';
import 'hadith_state.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<HadithCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const _HadithTitle(),
        actions: [
          BlocBuilder<HadithCubit, HadithState>(
            buildWhen: (a, b) =>
                (a is HadithReady &&
                    b is HadithReady &&
                    a.bookmarksOnly != b.bookmarksOnly) ||
                a.runtimeType != b.runtimeType,
            builder: (context, state) {
              final only = state is HadithReady && state.bookmarksOnly;
              return IconButton(
                tooltip: only ? loc.hadithShowAll : loc.hadithBookmarks,
                icon: Icon(
                  only ? Icons.bookmarks : Icons.bookmarks_outlined,
                ),
                onPressed: only ? cubit.showBrowse : cubit.showBookmarks,
              );
            },
          ),
        ],
      ),
      body: AppContentFrame.reading(
        child: Column(
          children: [
            const _SearchBar(),
            Expanded(
              child: BlocBuilder<HadithCubit, HadithState>(
                builder: (context, state) => switch (state) {
                  HadithLoading() => const LoadingView(),
                  HadithFailed() => errorPane(loc, onRetry: cubit.start),
                  final HadithReady ready when ready.items.isEmpty =>
                    EmptyState(
                      _emptyMessage(loc, ready),
                      icon: ready.bookmarksOnly
                          ? Icons.bookmarks_outlined
                          : Icons.menu_book_outlined,
                    ),
                  final HadithReady ready => Column(
                      children: [
                        Expanded(child: _HadithVerses(ready: ready)),
                        if (!ready.bookmarksOnly) _HadithPager(ready: ready),
                      ],
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _emptyMessage(AppLocalizations loc, HadithReady ready) {
    if (ready.bookmarksOnly) return loc.hadithNoBookmarks;
    if (ready.query.isNotEmpty) return loc.hadithSearchEmpty;
    return loc.hadithEmpty;
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<HadithCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: loc.hadithSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    cubit.clearSearch();
                    setState(() {});
                  },
                ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: cubit.search,
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
    final cubit = context.read<HadithCubit>();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: ready.items.length,
      itemBuilder: (context, index) {
        final (number, text) = ready.items[index];
        final rtl = ready.language == 'ar';
        if (text.isEmpty) {
          return const SizedBox.shrink();
        }
        return _HadithVerseRow(
          number: number,
          text: text,
          rtl: rtl,
          bookmarked: ready.bookmarked.contains(number),
          onToggle: () => cubit.toggleBookmark(number),
        );
      },
    );
  }
}

class _HadithVerseRow extends StatelessWidget {
  const _HadithVerseRow({
    required this.number,
    required this.text,
    required this.rtl,
    required this.bookmarked,
    required this.onToggle,
  });

  final int number;
  final String text;
  final bool rtl;
  final bool bookmarked;
  final VoidCallback onToggle;

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
          IconButton(
            tooltip: bookmarked ? loc.hadithUnbookmark : loc.hadithBookmark,
            icon: Icon(
              bookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: bookmarked ? colors.secondary : null,
            ),
            onPressed: onToggle,
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
