import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../l10n/app_localizations.dart';
import 'surah_index_body.dart';

/// The compact Quran tab: the surah list with the juz and search actions.
///
/// The list itself lives in [SurahIndexBody] so the expanded workspace can
/// render the same rows beside the reader.
class SurahIndexScreen extends StatelessWidget {
  /// Creates the screen.
  const SurahIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.quran),
        actions: [
          IconButton(
            tooltip: loc.juzIndexTitle,
            icon: const Icon(Icons.format_list_numbered),
            onPressed: () => context.push(AppRoutes.juzIndex),
          ),
          IconButton(
            tooltip: loc.searchQuranTitle,
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.quranSearch),
          ),
        ],
      ),
      body: AppContentFrame(
        child: SurahIndexBody(
          onSelect: (surah) => context.push(quranReaderPath(surah: surah.id)),
        ),
      ),
    );
  }
}
