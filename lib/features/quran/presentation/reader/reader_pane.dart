import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'reader_cubit.dart';
import 'reader_route_scope.dart';
import 'reader_screen.dart';
import 'reader_state.dart';

/// The reader inside the workspace detail pane.
///
/// It reuses [ReaderView] and [ReaderActions] but mounts neither a
/// [Scaffold] chrome of the full route nor a mini player: the shell owns the
/// player, and the workspace owns the page.
class ReaderPane extends StatelessWidget {
  /// Creates the pane for one `(surah, ayah)` selection.
  const ReaderPane({
    super.key,
    required this.surah,
    required this.ayah,
    required this.createReader,
    this.onOpenBookmarks,
    this.onBack,
    this.onOpenAyah,
  });

  /// The selected surah.
  final int surah;

  /// The initial ayah; 0 starts at the surah's first ayah.
  final int ayah;

  /// Builds the reader cubit; the scope starts it.
  final ReaderCubit Function(int surah, int ayah) createReader;

  /// The bookmarks action; null keeps the route push.
  final VoidCallback? onOpenBookmarks;

  /// The explicit back action; null keeps the Navigator's own leading.
  final VoidCallback? onBack;

  /// The page-jump destination; null keeps the full-reader push.
  final void Function(int surah, int ayah)? onOpenAyah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ReaderRouteScope(
      surah: surah,
      ayah: ayah,
      create: () => createReader(surah, ayah),
      child: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (context, state) => switch (state) {
          ReaderLoading() => Scaffold(
              appBar: _bar(loc.quran),
              body: const LoadingView(),
            ),
          ReaderFailed() => Scaffold(
              appBar: _bar(loc.quran),
              body: ReaderErrorBody(state: state),
            ),
          ReaderReady() => Scaffold(
              appBar: _bar(
                state.surahName,
                actions: [
                  ReaderActions(
                    state: state,
                    onOpenBookmarks: onOpenBookmarks,
                    onOpenAyah: onOpenAyah,
                  ),
                ],
              ),
              body: ReaderView(state: state),
            ),
        },
      ),
    );
  }

  AppBar _bar(String title, {List<Widget>? actions}) {
    // `primary: false`: the workspace AppBar already consumed the status bar,
    // so this is a pane toolbar, not a second screen app bar.
    return AppBar(
      primary: false,
      title: Text(title),
      actions: actions,
      leading: onBack == null ? null : BackButton(onPressed: onBack),
    );
  }
}
