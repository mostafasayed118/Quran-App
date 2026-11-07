import 'package:flutter/material.dart';

import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/routing/route_cubit_scope.dart';
import '../../../../core/utils/app_routes.dart';
import '../bookmarks/bookmarks_cubit.dart';
import '../index/juz_index_cubit.dart';
import '../index/surah_index_screen.dart';
import '../reader/reader_cubit.dart';
import 'quran_workspace_screen.dart';

/// Chooses the Quran tab presentation by window width.
///
/// Below the expanded breakpoint it is the unchanged surah index. From 840 dp
/// it mounts the three master scopes and the two-pane workspace; the extra
/// cubits are created by the route-supplied factories only in that branch.
class QuranTabScreen extends StatelessWidget {
  /// Creates the tab; the factories stay in the composition root.
  const QuranTabScreen({
    super.key,
    required this.createReader,
    required this.createJuz,
    required this.createBookmarks,
  });

  /// Builds a side-effect-free reader cubit for one selection.
  final ReaderCubit Function(int surah, int ayah) createReader;

  /// Builds the juz master cubit.
  final JuzIndexCubit Function() createJuz;

  /// Builds the bookmarks master cubit.
  final BookmarksCubit Function() createBookmarks;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isExpanded(context)) {
      return const SurahIndexScreen();
    }
    return RouteCubitScope<JuzIndexCubit>(
      identity: AppRoutes.quran,
      create: createJuz,
      start: (cubit) => cubit.start(),
      child: RouteCubitScope<BookmarksCubit>(
        identity: AppRoutes.quran,
        create: createBookmarks,
        start: (cubit) => cubit.start(),
        child: QuranWorkspaceScreen(createReader: createReader),
      ),
    );
  }
}
