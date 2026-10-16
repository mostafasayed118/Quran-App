import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
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
            body: ErrorView(message),
          ),
        BookmarksReady(:final entries) => Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).bookmarks),
            ),
            body: entries.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context).noBookmarks),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final ayah = entries[index].ayah;
                      final snippet = ayah.textImlaei.length > 60
                          ? '${ayah.textImlaei.substring(0, 60)}…'
                          : ayah.textImlaei;
                      return ListTile(
                        leading: Text(
                          '${ayah.surahId.toArabicIndic}:${ayah.numberInSurah.toArabicIndic}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: Text(snippet),
                        subtitle: Text(
                          '${ayah.surahId.toArabicIndic} · ${ayah.numberInSurah.toArabicIndic}',
                        ),
                        trailing: IconButton(
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
