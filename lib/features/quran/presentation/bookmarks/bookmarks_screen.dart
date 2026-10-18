import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/arabic_numbers.dart';
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
        BookmarksError(:final message) => Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).bookmarks)),
            body: errorPane(AppLocalizations.of(context), message, 'bookmarks'),
          ),
        BookmarksReady(:final entries) => Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).bookmarks),
            ),
            body: entries.isEmpty
                ? EmptyState(
                    AppLocalizations.of(context).noBookmarks,
                    actionLabel: AppLocalizations.of(context).quran,
                    onAction: () => context.push('/quran'),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
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
                          tooltip: AppLocalizations.of(context).bookmarkRemove,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              context.read<BookmarksCubit>().remove(ayah.id),
                        ),
                        onTap: () => context.push(
                            '/quran/reader?surah=${ayah.surahId}&ayah=${ayah.numberInSurah}'),
                      );
                    },
                  ),
          ),
      },
    );
  }
}
