import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/deep_links.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
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
      buildWhen: readerShellShouldRebuild,
      builder: (context, state) => switch (state) {
        ReaderLoading() => const Scaffold(body: LoadingView()),
        ReaderFailed() => _ReaderErrorView(state: state),
        ReaderReady() => _ReadyView(state: state),
      },
    );
  }
}

/// The reader shell rebuilds on every state change EXCEPT a bookmark-only
/// one: the bookmark UI carries its own subscription (one [BlocSelector] per
/// verse), so toggling a bookmark no longer rebuilds the whole Scaffold.
bool readerShellShouldRebuild(ReaderState previous, ReaderState current) {
  if (previous is! ReaderReady || current is! ReaderReady) return true;
  // Equal apart from the bookmarks means the shell has nothing new to show.
  return previous.copyWith(bookmarkedAyahIds: current.bookmarkedAyahIds) !=
      current;
}

class _ReaderErrorView extends StatelessWidget {
  const _ReaderErrorView({required this.state});

  final ReaderFailed state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final emptySurahId = state.emptySurahId;
    return Scaffold(
      appBar: AppBar(title: Text(loc.quran)),
      body: Column(
        children: [
          Expanded(
            child: emptySurahId == null
                ? errorPane(loc)
                // A surah without readable ayahs is its own failure: the
                // generic pane would blame a transient error.
                : ErrorView(loc.readerNoAyahs(emptySurahId.toArabicIndic)),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 32 + appBottomInset(context)),
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
                  surahName: state.surahName,
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
            onPressed: () => context.push(AppRoutes.bookmarks),
          ),
          IconButton(
            tooltip: loc.pageJump,
            icon: const Icon(Icons.pin_outlined),
            onPressed: () => unawaited(_openPageJump(context, cubit, loc)),
          ),
          IconButton(
            tooltip: loc.readerFontSize,
            icon: const Icon(Icons.format_size),
            onPressed: () => _showFontSheet(context, cubit, state.fontScale),
          ),
        ],
      ),
      // Selection is enabled only when the surah's Unicode Uthmani asset is
      // present: the fallback glyph column is a private-use encoding, and
      // selecting it used to copy `   …` into WhatsApp. With the Unicode
      // text the selection is real Arabic and the native toolbar is correct.
      body: Builder(
        builder: (context) {
          final content = Column(
            children: [
              if (state.showBasmala)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    loc.basmala,
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
          );
          return state.ayahs.every((v) => v.textUnicode != null)
              ? SelectionArea(child: content)
              : content;
        },
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

  /// Tracks the first verse the reader can see, so the Home continue-reading
  /// card advances in the default verse mode as well as in mushaf mode.
  final ItemPositionsListener _positions = ItemPositionsListener.create();

  /// The list's start index, computed once per surah: scanning the surah on
  /// every build re-ran the scan on each rebuild.
  late final int _initialIndex;
  int? _lastReportedIndex;

  @override
  void initState() {
    super.initState();
    final state = widget.state;
    final index =
        state.ayahs.indexWhere((a) => a.numberInSurah == state.initialAyah);
    _initialIndex = index > 0 ? index : 0;
    _positions.itemPositions.addListener(_reportFirstVisible);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_reportFirstVisible);
    super.dispose();
  }

  void _reportFirstVisible() {
    if (!mounted) return;
    final visible = _positions.itemPositions.value
        .where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1)
        .toList();
    if (visible.isEmpty) return;
    visible.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final index = visible.first.index;
    if (index == _lastReportedIndex) return;
    final state = widget.state;
    if (index < 0 || index >= state.ayahs.length) return;
    final firstReport = _lastReportedIndex == null;
    _lastReportedIndex = index;
    // The initial load already saved the requested start. If the list's first
    // layout report is index 0 before the initial scroll is applied, do not
    // overwrite that marker with the top of the surah.
    if (firstReport && index != _initialIndex) return;
    unawaited(context.read<ReaderCubit>().onVisibleAyah(state.ayahs[index].id));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final state = widget.state;
    return ScrollablePositionedList.builder(
      initialScrollIndex: _initialIndex,
      itemScrollController: _controller,
      itemPositionsListener: _positions,
      padding: EdgeInsets.only(bottom: appBottomInset(context)),
      itemCount: state.ayahs.length,
      itemBuilder: (context, index) {
        final ayah = state.ayahs[index];
        // The bookmark flag is its own subscription: a bookmark toggle
        // rebuilds this card alone, not the verse list and not the Scaffold.
        return BlocSelector<ReaderCubit, ReaderState, bool>(
          selector: (s) =>
              s is ReaderReady && s.bookmarkedAyahIds.contains(ayah.id),
          builder: (context, bookmarked) => _AyahCard(
            ayah: ayah,
            surahName: state.surahName,
            bookmarked: bookmarked,
            fontScale: state.fontScale,
            onToggle: () =>
                toggleAyahBookmark(context, cubit, ayah.id, bookmarked),
          ),
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
    required this.fontScale,
    required this.onToggle,
  });

  final Verse ayah;
  final String surahName;
  final bool bookmarked;
  final double fontScale;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
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
          // With Unicode text the SelectionArea owns the long-press (that is
          // how a selection starts). Only the glyph fallback needs the
          // copy-on-long-press shortcut, because selection there is invalid.
          Builder(
            builder: (context) {
              final unicode = ayah.textUnicode;
              final text = unicode ?? stripAyahEndMarker(ayah.textUthmani);
              final widget = Text(
                text,
                style: AppTheme.hafsAyah.copyWith(
                  fontSize: AppTheme.hafsAyah.fontSize! * fontScale,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              );
              if (unicode != null) return widget;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => copyAyahText(context, ayah),
                child: widget,
              );
            },
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
            // The drag handle is part of the sheet's contract (pinned by the
            // textScale probe); the rounded strip above the card is intended.
            showDragHandle: true,
            builder: (_) => AyahSheet(
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
        _CopyAyahButton(ayah: ayah),
        _ShareAyahButton(ayah: ayah),
      ],
    );
  }
}

/// Copies [ayah] as real Arabic and confirms it.
///
/// The mushaf renders `text_uthmani`, a private-use glyph encoding only the
/// bundled Hafs face understands; `text_imlaei` is the copyable, searchable
/// orthography. Shared by the copy button and the long-press on the verse.
Future<void> copyAyahText(BuildContext context, Verse ayah) async {
  final loc = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: ayah.copyText));
  AppToast.showOn(messenger, loc.ayahCopied, tone: ToastTone.success);
}

/// Toggles the bookmark of [ayahId] and confirms what changed.
///
/// [bookmarked] is the state *before* the tap, so the copy names the change
/// that just happened. A failed write is surfaced instead of swallowed: the
/// star would otherwise stay unchanged with no explanation.
Future<void> toggleAyahBookmark(
  BuildContext context,
  ReaderCubit cubit,
  int ayahId,
  bool bookmarked,
) async {
  final loc = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final saved = await cubit.toggleBookmark(ayahId);
  if (!saved) {
    AppToast.showOn(messenger, loc.genericError, tone: ToastTone.error);
    return;
  }
  AppToast.showOn(
    messenger,
    bookmarked ? loc.bookmarkRemoved : loc.bookmarkSaved,
    tone: ToastTone.success,
  );
}

/// Copies the verse as real Arabic.
///
/// The rendered mushaf glyphs are a private-use encoding of `text_uthmani`,
/// so the clipboard must take `text_imlaei` (the same column the share action
/// and the bookmarks list use) or other apps receive boxes.
class _CopyAyahButton extends StatelessWidget {
  const _CopyAyahButton({required this.ayah});

  final Verse ayah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return IconButton(
      tooltip: loc.copyAyah,
      icon: const Icon(Icons.copy_outlined),
      onPressed: () => copyAyahText(context, ayah),
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
        text: loc.shareAyahText(
          ayah.copyText,
          webSurahUrl(ayah.surahId, ayah.numberInSurah),
        ),
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
        // The page is one shaped paragraph: the verse text plus a me_quran
        // ornament for the number (the face that actually has U+FD3F/FD3E).
        // The text is the Unicode Uthmani asset when available; the glyph
        // column is the fallback and carries its own end marker.
        final unicode = block.ayahs.every((a) => a.textUnicode != null);
        final numberStyle = TextStyle(
          fontFamily: QuranFonts.meQuran,
          color: AppTheme.goldText(context),
        );
        final spans = <InlineSpan>[
          for (final a in block.ayahs) ...[
            // Non-breaking space: the medallion must wrap WITH the ayah's last
            // word, never land at the start of the next line (where it would
            // read as if it belonged to the following verse).
            TextSpan(
              text:
                  '${a.textUnicode ?? stripAyahEndMarker(a.textUthmani)}\u00A0',
            ),
            TextSpan(
              text: '${loc.ornateBrackets(a.numberInSurah.toArabicIndic)} ',
              style: numberStyle,
            ),
          ],
        ];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + appBottomInset(context),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text.rich(
                    TextSpan(children: spans),
                    style: unicode
                        ? AppTheme.hafsAyah.copyWith(
                            fontSize: 22 * widget.state.fontScale,
                            height: 2.2,
                          )
                        : TextStyle(
                            fontFamily: QuranFonts.quran,
                            fontSize: 22 * widget.state.fontScale,
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

/// Resolves a page to the reader's (surah, ayah) route.
Future<void> _openPageJump(
  BuildContext context,
  ReaderCubit cubit,
  AppLocalizations loc,
) async {
  final page = await showDialog<int>(
    context: context,
    builder: (_) => _PageJumpDialog(loc: loc),
  );
  if (!context.mounted || page == null) return;
  if (page < 1 || page > 604) {
    _showInvalidPage(context, loc);
    return;
  }
  final anchor = await cubit.anchorForPage(page);
  if (!context.mounted) return;
  if (anchor == null) {
    _showInvalidPage(context, loc);
    return;
  }
  unawaited(context.push(
    quranReaderPath(surah: anchor.surahId, ayah: anchor.numberInSurah),
  ));
}

void _showInvalidPage(BuildContext context, AppLocalizations loc) {
  AppToast.show(context, loc.pageJumpInvalid, tone: ToastTone.error);
}

/// The page-number dialog.
///
/// It owns the controller so the controller lives exactly as long as the route.
/// Disposing it when `showDialog`'s future completes is a frame too early: the
/// exit transition still rebuilds the field, which then uses a disposed
/// controller.
class _PageJumpDialog extends StatefulWidget {
  const _PageJumpDialog({required this.loc});

  final AppLocalizations loc;

  @override
  State<_PageJumpDialog> createState() => _PageJumpDialogState();
}

class _PageJumpDialogState extends State<_PageJumpDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(int.tryParse(_controller.text.toWesternDigits));
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return AlertDialog(
      title: Text(loc.pageJump),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: loc.pageJumpHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(loc.pageJumpGo)),
      ],
    );
  }
}

void _showFontSheet(
  BuildContext context,
  ReaderCubit cubit,
  double initial,
) {
  var value = initial;
  unawaited(showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).readerFontSize,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: value,
                min: 0.8,
                max: 2,
                divisions: 12,
                label: value.toStringAsFixed(1),
                onChanged: (next) {
                  setSheetState(() => value = next);
                  unawaited(cubit.setFontScale(next));
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}
