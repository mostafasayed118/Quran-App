part of 'reader_screen.dart';

/// The reader body: basmala, verse list or mushaf pager, and the selection
/// layer. No Scaffold and no mini player, so the workspace pane can mount it
/// beside the master list.
class ReaderView extends StatelessWidget {
  /// Creates the body for [state].
  const ReaderView({super.key, required this.state});

  /// The ready reader state.
  final ReaderReady state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isVerses = state.mode == ReaderMode.verses;
    // Selection is enabled only when the surah's Unicode Uthmani asset is
    // present: the fallback glyph column is a private-use encoding, and
    // selecting it used to copy private-use glyphs into WhatsApp. With the
    // Unicode text the selection is real Arabic and the native toolbar is
    // correct.
    return AppContentFrame.reading(
      child: Builder(
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
    );
  }
}

/// The five reader AppBar actions, shared by the full route and the pane.
class ReaderActions extends StatelessWidget {
  /// Creates the actions; [onOpenBookmarks] and [onOpenAyah] override pushes.
  const ReaderActions({
    super.key,
    required this.state,
    this.onOpenBookmarks,
    this.onOpenAyah,
  });

  /// The ready reader state.
  final ReaderReady state;

  /// The bookmarks action; null keeps the route push.
  final VoidCallback? onOpenBookmarks;

  /// The page-jump destination; null keeps the reader-route push.
  final void Function(int surah, int ayah)? onOpenAyah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<ReaderCubit>();
    final isVerses = state.mode == ReaderMode.verses;

    final listen = IconButton(
      tooltip: loc.listenTooltip,
      icon: const Icon(Icons.headphones),
      onPressed: () => context.read<PlaybackCubit>().playDefaultForSurah(
            state.surahId,
            surahName: state.surahName,
          ),
    );
    final bookmarks = IconButton(
      tooltip: loc.bookmarks,
      icon: const Icon(Icons.bookmarks_outlined),
      onPressed: onOpenBookmarks ?? () => context.push(AppRoutes.bookmarks),
    );
    final pageJump = IconButton(
      tooltip: loc.pageJump,
      icon: const Icon(Icons.pin_outlined),
      onPressed: () => unawaited(
        _openPageJump(context, cubit, loc, onResolved: onOpenAyah),
      ),
    );

    // Five icons plus a long surah title do not fit a 360 dp bar at
    // textScale 2.0: fold the two display toggles into one menu there.
    if (MediaQuery.sizeOf(context).width < 400) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          listen,
          bookmarks,
          pageJump,
          PopupMenuButton<_ReaderMoreAction>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (action) {
              switch (action) {
                case _ReaderMoreAction.mode:
                  cubit.toggleMode();
                case _ReaderMoreAction.font:
                  _showFontSheet(
                    context,
                    cubit,
                    state.fontScale,
                    state.lineHeight,
                  );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ReaderMoreAction.mode,
                child: ListTile(
                  leading:
                      Icon(isVerses ? Icons.menu_book : Icons.auto_stories),
                  title: Text(isVerses ? loc.mushafMode : loc.versesMode),
                ),
              ),
              PopupMenuItem(
                value: _ReaderMoreAction.font,
                child: ListTile(
                  leading: const Icon(Icons.format_size),
                  title: Text(loc.readerFontSize),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        listen,
        IconButton(
          tooltip: isVerses ? loc.mushafMode : loc.versesMode,
          icon: Icon(isVerses ? Icons.menu_book : Icons.auto_stories),
          onPressed: cubit.toggleMode,
        ),
        bookmarks,
        pageJump,
        IconButton(
          tooltip: loc.readerFontSize,
          icon: const Icon(Icons.format_size),
          onPressed: () => _showFontSheet(
            context,
            cubit,
            state.fontScale,
            state.lineHeight,
          ),
        ),
      ],
    );
  }
}

enum _ReaderMoreAction { mode, font }
