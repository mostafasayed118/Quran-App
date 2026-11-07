import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../bookmarks/bookmarks_body.dart';
import '../index/juz_index_body.dart';
import '../index/surah_index_body.dart';
import '../reader/reader_cubit.dart';
import '../reader/reader_pane.dart';

/// The expanded Quran tab: a three-tab master pane beside a reader pane.
///
/// The pane is driven by a declarative [Navigator]: the empty prompt is the
/// first page and the selected reader is the second, so back always returns
/// to the prompt without touching the router (the URL stays `/quran`).
class QuranWorkspaceScreen extends StatefulWidget {
  /// Creates the workspace; [createReader] builds a side-effect-free cubit.
  const QuranWorkspaceScreen({super.key, required this.createReader});

  /// Builds the reader cubit for one selection; the pane scope starts it.
  final ReaderCubit Function(int surah, int ayah) createReader;

  @override
  State<QuranWorkspaceScreen> createState() => _QuranWorkspaceScreenState();
}

class _QuranWorkspaceScreenState extends State<QuranWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  ({int surah, int ayah})? _selection;
  int? _selectedJuz;
  int? _selectedAyahId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _select({required int surah, required int ayah, int? juz, int? ayahId}) {
    setState(() {
      _selection = (surah: surah, ayah: ayah);
      _selectedJuz = juz;
      _selectedAyahId = ayahId;
    });
  }

  void _clearSelection() {
    setState(() {
      _selection = null;
      _selectedJuz = null;
      _selectedAyahId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final masterWidth = width >= 1024 ? 340.0 : 300.0;
    final selection = _selection;

    return PopScope(
      canPop: selection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.quran),
          actions: [
            IconButton(
              tooltip: loc.searchQuranTitle,
              icon: const Icon(Icons.search),
              onPressed: () => context.push(AppRoutes.quranSearch),
            ),
          ],
        ),
        body: Row(
          children: [
            SizedBox(
              key: const Key('quran-master'),
              width: masterWidth,
              child: ClipRect(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabs: [
                        Tab(text: loc.quran),
                        Tab(text: loc.juzIndexTitle),
                        Tab(text: loc.bookmarks),
                      ],
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _tabs.index,
                        children: [
                          SurahIndexBody(
                            onSelect: (surah) =>
                                _select(surah: surah.id, ayah: 0),
                            selectedSurahId: selection?.surah,
                          ),
                          JuzIndexBody(
                            onSelect: (juz) => _select(
                              surah: juz.surahId,
                              ayah: juz.numberInSurah,
                              juz: juz.juz,
                            ),
                            selectedJuz: _selectedJuz,
                          ),
                          BookmarksBody(
                            onSelect: (verse) => _select(
                              surah: verse.surahId,
                              ayah: verse.numberInSurah,
                              ayahId: verse.id,
                            ),
                            selectedAyahId: _selectedAyahId,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              key: const Key('quran-detail'),
              child: Navigator(
                pages: [
                  const MaterialPage(
                    key: ValueKey('quran-empty'),
                    child: _EmptyDetail(),
                  ),
                  if (selection != null)
                    MaterialPage(
                      key: ValueKey(
                        'quran-reader-${selection.surah}-${selection.ayah}',
                      ),
                      child: ReaderPane(
                        surah: selection.surah,
                        ayah: selection.ayah,
                        createReader: widget.createReader,
                        onOpenBookmarks: () => _tabs.index = 2,
                        onBack: _clearSelection,
                      ),
                    ),
                ],
                onDidRemovePage: (page) {
                  if (page.key != const ValueKey('quran-empty')) {
                    _clearSelection();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      AppLocalizations.of(context).quranWorkspacePrompt,
      icon: Icons.menu_book_outlined,
    );
  }
}
