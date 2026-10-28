import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'bookmarks_cubit.dart';
import 'bookmarks_state.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarksCubit, BookmarksState>(
      builder: (context, state) => switch (state) {
        BookmarksLoading() => const Scaffold(body: LoadingView()),
        BookmarksFailed() => Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).bookmarks)),
            body: errorPane(AppLocalizations.of(context)),
          ),
        BookmarksReady() => Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).bookmarks),
            ),
            body: state.entries.isEmpty
                ? EmptyState(
                    AppLocalizations.of(context).noBookmarks,
                    actionLabel: AppLocalizations.of(context).quran,
                    onAction: () => context.push(AppRoutes.quran),
                  )
                : _BookmarkList(state: state),
          ),
      },
    );
  }
}

class _BookmarkList extends StatelessWidget {
  const _BookmarkList({required this.state});

  final BookmarksReady state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final showTail = state.hasMore || state.loadingMore || state.moreFailed;
    final entries = state.entries;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) {
          context.read<BookmarksCubit>().loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: appBottomInset(context)),
        itemCount: entries.length + (showTail ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == entries.length) return _tail(context, loc);
          final ayah = entries[index];
          return ListTile(
            leading: Text(
              '${ayah.surahId.toArabicIndic}:${ayah.numberInSurah.toArabicIndic}',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            title: Text(
              ayah.textImlaei,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: loc.bookmarkRemove,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => context.read<BookmarksCubit>().remove(ayah.id),
            ),
            onTap: () => context.push(quranReaderPath(
              surah: ayah.surahId,
              ayah: ayah.numberInSurah,
            )),
          );
        },
      ),
    );
  }

  Widget _tail(BuildContext context, AppLocalizations loc) {
    if (state.moreFailed) {
      return Center(
        child: TextButton(
          onPressed: context.read<BookmarksCubit>().retryMore,
          child: Text(loc.retry),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
