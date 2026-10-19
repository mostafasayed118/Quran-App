import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/deep_links.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../library/presentation/ayah_sheet/library_sheet.dart';
import '../../../recitation/presentation/playback/mini_player_bar.dart';
import '../../../recitation/presentation/playback/playback_cubit.dart';
import '../../domain/verse.dart';
import 'reader_cubit.dart';
import 'reader_state.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) => switch (state) {
        ReaderLoading() => const Scaffold(body: LoadingView()),
        ReaderError(:final message) => _ReaderErrorView(message: message),
        ReaderReady() => _ReadyView(state: state),
      },
    );
  }
}

class _ReaderErrorView extends StatelessWidget {
  const _ReaderErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.quran)),
      body: Column(
        children: [
          Expanded(child: errorPane(loc, message, 'reader')),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: FilledButton(
              onPressed: () => context.read<ReaderCubit>().reload(),
              child: Text(loc.retry),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state});

  final ReaderReady state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<ReaderCubit>();
    final isVerses = state.mode == ReaderMode.verses;
    return Scaffold(
      appBar: AppBar(
        title: Text(state.surahName),
        actions: [
          IconButton(
            tooltip: loc.listenTooltip,
            icon: const Icon(Icons.headphones),
            onPressed: () => context.read<PlaybackCubit>().playDefaultForSurah(
                  state.surahId,
                ),
          ),
          IconButton(
            tooltip: isVerses ? loc.mushafMode : loc.versesMode,
            icon: Icon(isVerses ? Icons.menu_book : Icons.auto_stories),
            onPressed: cubit.toggleMode,
          ),
          IconButton(
            tooltip: loc.bookmarks,
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push('/bookmarks'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.showBasmala)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  fontSize: 22,
                  color: AppTheme.goldText(context),
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          Expanded(
            child: isVerses
                ? _VersesList(state: state)
                : _MushafPager(state: state),
          ),
        ],
      ),
      bottomSheet: const MiniPlayerBar(),
    );
  }
}

class _VersesList extends StatefulWidget {
  const _VersesList({required this.state});

  final ReaderReady state;

  @override
  State<_VersesList> createState() => _VersesListState();
}

class _VersesListState extends State<_VersesList> {
  /// Hoisted to State: rebuilds (bookmark emissions) must not replace the
  /// controller mid-scroll, which re-applied initialScrollIndex.
  final ItemScrollController _controller = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final state = widget.state;
    final initialIndex =
        state.ayahs.indexWhere((a) => a.numberInSurah == state.initialAyah);
    return ScrollablePositionedList.builder(
      initialScrollIndex: initialIndex > 0 ? initialIndex : 0,
      itemScrollController: _controller,
      itemCount: state.ayahs.length,
      itemBuilder: (context, index) {
        final ayah = state.ayahs[index];
        return _AyahCard(
          ayah: ayah,
          surahName: state.surahName,
          bookmarked: state.bookmarkedAyahIds.contains(ayah.id),
          onToggle: () => cubit.toggleBookmark(ayah.id),
        );
      },
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
    required this.surahName,
    required this.bookmarked,
    required this.onToggle,
  });

  final Verse ayah;
  final String surahName;
  final bool bookmarked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bookmarked ? colors.secondary : Theme.of(context).dividerColor,
          width: bookmarked ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            ayah.textUthmani,
            style: AppTheme.hafsAyah,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          _AyahActions(
            ayah: ayah,
            surahName: surahName,
            bookmarked: bookmarked,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }
}

class _AyahActions extends StatelessWidget {
  const _AyahActions({
    required this.ayah,
    required this.surahName,
    required this.bookmarked,
    required this.onToggle,
  });

  final Verse ayah;
  final String surahName;
  final bool bookmarked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          loc.ornateBrackets(ayah.numberInSurah.toArabicIndic),
          style: TextStyle(
            fontFamily: QuranFonts.meQuran,
            fontSize: 16,
            color: AppTheme.goldText(context),
          ),
          semanticsLabel: loc.ayahNumberLabel(ayah.numberInSurah.toArabicIndic),
        ),
        const Spacer(),
        IconButton(
          tooltip: loc.ayahSheetTitle,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => LibrarySheet(
              surahId: ayah.surahId,
              surahName: surahName,
              ayah: ayah.numberInSurah,
            ),
          ),
        ),
        IconButton(
          tooltip: bookmarked ? loc.bookmarkRemove : loc.bookmarkSave,
          icon: Icon(
            bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: bookmarked ? colors.secondary : null,
          ),
          onPressed: onToggle,
        ),
        _ShareAyahButton(ayah: ayah),
      ],
    );
  }
}

class _ShareAyahButton extends StatelessWidget {
  const _ShareAyahButton({required this.ayah});

  final Verse ayah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return IconButton(
      tooltip: loc.shareAyah,
      icon: const Icon(Icons.share_outlined),
      onPressed: () => SharePlus.instance.share(ShareParams(
        text:
            '${ayah.textImlaei}\n\n${webSurahUrl(ayah.surahId, ayah.numberInSurah)}',
      )),
    );
  }
}

class _MushafPager extends StatefulWidget {
  const _MushafPager({required this.state});

  final ReaderReady state;

  @override
  State<_MushafPager> createState() => _MushafPagerState();
}

class _MushafPagerState extends State<_MushafPager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    final pages = widget.state.mushafPages;
    final target = widget.state.ayahs
        .where((a) => a.numberInSurah == widget.state.initialAyah)
        .toList();
    var index = 0;
    if (target.isNotEmpty) {
      final idx = pages.indexWhere((b) => b.page == target.first.page);
      if (idx > 0) index = idx;
    }
    _controller = PageController(initialPage: index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final loc = AppLocalizations.of(context);
    final pages = widget.state.mushafPages;
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }
    return PageView.builder(
      controller: _controller,
      itemCount: pages.length,
      onPageChanged: cubit.onMushafPageChanged,
      itemBuilder: (context, i) {
        final block = pages[i];
        final text = block.ayahs
            .map((a) =>
                '${a.textUthmani} ${loc.ornateBrackets(a.numberInSurah.toArabicIndic)}')
            .join(' ');
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: QuranFonts.quran,
                      fontSize: 22,
                      height: 2.2,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              Text(
                loc.ornateBrackets(
                  loc.pageIndicator(block.page.toArabicIndic),
                ),
                style: TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  color: AppTheme.goldText(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
