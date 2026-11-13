part of 'reader_screen.dart';

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
    final anchor = widget.state.currentAyahId;
    final target = anchor > 0
        ? widget.state.ayahs.where((a) => a.id == anchor).toList()
        : widget.state.ayahs
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
              text: '${a.displayText}\u00A0',
            ),
            TextSpan(
              text: '${loc.ornateBrackets(loc.number(a.numberInSurah))} ',
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
                            fontSize:
                                AppType.quranMushaf * widget.state.fontScale,
                            height: widget.state.lineHeight,
                          )
                        : TextStyle(
                            fontFamily: QuranFonts.quran,
                            fontSize:
                                AppType.quranMushaf * widget.state.fontScale,
                            height: widget.state.lineHeight,
                          ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              Text(
                loc.ornateBrackets(
                  loc.pageIndicator(loc.number(block.page)),
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
  AppLocalizations loc, {
  void Function(int surah, int ayah)? onResolved,
}) async {
  final page = await showDialog<int>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _PageJumpDialog(loc: loc),
  );
  if (!context.mounted || page == null) return;
  if (page < 1 || page > kMushafPageCount) {
    _showInvalidPage(context, loc);
    return;
  }
  final anchor = await cubit.anchorForPage(page);
  if (!context.mounted) return;
  if (anchor == null) {
    _showInvalidPage(context, loc);
    return;
  }
  if (onResolved != null) {
    onResolved(anchor.surahId, anchor.numberInSurah);
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
    final page = int.tryParse(_controller.text.toWesternDigits);
    if (page == null) {
      AppToast.show(context, widget.loc.pageJumpInvalid, tone: ToastTone.error);
      return;
    }
    Navigator.of(context).pop(page);
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
  double initialLineHeight,
) {
  var value = initial;
  var lineHeight = initialLineHeight;
  unawaited(showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context).readerLineSpacing,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: lineHeight,
                  min: ReaderLayoutSource.minLineHeight,
                  max: ReaderLayoutSource.maxLineHeight,
                  divisions: 14,
                  label: lineHeight.toStringAsFixed(1),
                  onChanged: (next) {
                    setSheetState(() => lineHeight = next);
                    unawaited(cubit.setLineHeight(next));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
}
