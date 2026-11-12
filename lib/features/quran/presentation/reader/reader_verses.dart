part of 'reader_screen.dart';

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state});

  final ReaderReady state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // A long surah name at textScale 2.0 would ellipsize in a 360 dp bar;
        // scale it down instead so the full name stays readable.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(state.surahName),
        ),
        actions: [ReaderActions(state: state)],
      ),
      body: ReaderView(state: state),
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
    final anchor = state.currentAyahId;
    final index = anchor > 0
        ? state.ayahs.indexWhere((a) => a.id == anchor)
        : state.ayahs.indexWhere((a) => a.numberInSurah == state.initialAyah);
    _initialIndex = index > 0 ? index : 0;
    _positions.itemPositions.addListener(_reportFirstVisible);
  }

  /// Which ayah has its action row open. One at a time: opening another closes
  /// the previous one, and tapping the open card again closes it. The row used
  /// to render on every verse, which spent roughly 40% of the reader's height
  /// on chrome (2026-11-13 UI audit, finding U-1).
  int? _openAyahId;

  void _toggleActions(int ayahId) {
    setState(() => _openAyahId = _openAyahId == ayahId ? null : ayahId);
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
            lineHeight: state.lineHeight,
            actionsOpen: _openAyahId == ayah.id,
            onTap: () => _toggleActions(ayah.id),
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
    required this.lineHeight,
    required this.actionsOpen,
    required this.onTap,
    required this.onToggle,
  });

  final Verse ayah;
  final String surahName;
  final bool bookmarked;
  final double fontScale;
  final double lineHeight;
  final bool actionsOpen;
  final VoidCallback onTap;
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
                final text = ayah.displayText;
                final widget = Text(
                  text,
                  style: AppTheme.hafsAyah.copyWith(
                    fontSize: AppTheme.hafsAyah.fontSize! * fontScale,
                    height: lineHeight,
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
              open: actionsOpen,
              onToggle: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahActions extends StatelessWidget {
  const _AyahActions({
    required this.ayah,
    required this.surahName,
    required this.bookmarked,
    required this.open,
    required this.onToggle,
  });

  final Verse ayah;
  final String surahName;
  final bool bookmarked;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          loc.ornateBrackets(loc.number(ayah.numberInSurah)),
          style: TextStyle(
            fontFamily: QuranFonts.meQuran,
            fontSize: 16,
            color: AppTheme.goldText(context),
          ),
          semanticsLabel: loc.ayahNumberLabel(loc.number(ayah.numberInSurah)),
        ),
        const Spacer(),
        // Only the buttons collapse; the ayah number is part of reading and
        // stays visible (the 2.0 probe reads its semantics label).
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: AlignmentDirectional.centerEnd,
          child: open
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: loc.ayahSheetTitle,
                      icon: const Icon(Icons.menu_book_outlined),
                      onPressed: () => showAppSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AyahSheet(
                          surahId: ayah.surahId,
                          surahName: surahName,
                          ayah: ayah.numberInSurah,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          bookmarked ? loc.bookmarkRemove : loc.bookmarkSave,
                      icon: Icon(
                        bookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: bookmarked ? colors.secondary : null,
                      ),
                      onPressed: onToggle,
                    ),
                    _CopyAyahButton(ayah: ayah),
                    _ShareAyahButton(ayah: ayah, surahName: surahName),
                  ],
                )
              : const SizedBox.shrink(),
        ),
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
  const _ShareAyahButton({required this.ayah, required this.surahName});

  final Verse ayah;
  final String surahName;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return IconButton(
      tooltip: loc.shareAyah,
      icon: const Icon(Icons.share_outlined),
      onPressed: () => showVerseShareSheet(
        context,
        ayah: ayah,
        surahName: surahName,
      ),
    );
  }
}
