import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../l10n/app_localizations.dart';
import 'bookmarks_body.dart';

/// The compact bookmark route: the shared list plus the folder/note layer.
class BookmarksScreen extends StatelessWidget {
  /// Creates the screen.
  ///
  /// [showMeta] opts into the folder chips and the note/folder editor; the
  /// route supplies the [BookmarkMetaCubit] then. Tests that only exercise the
  /// bookmark list keep the default and need no meta provider.
  const BookmarksScreen({super.key, this.showMeta = false});

  /// Whether the folder/note layer is rendered.
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.bookmarks)),
      body: AppContentFrame(
        child: BookmarksBody(
          showMeta: showMeta,
          onBrowseQuran: () => context.push(AppRoutes.quran),
          onSelect: (verse) => context.push(
            quranReaderPath(
              surah: verse.surahId,
              ayah: verse.numberInSurah,
            ),
          ),
        ),
      ),
    );
  }
}
