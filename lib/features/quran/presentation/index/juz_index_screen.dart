import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../l10n/app_localizations.dart';
import 'juz_index_body.dart';

/// The 30 juz starts; each opens the reader at its first ayah.
class JuzIndexScreen extends StatelessWidget {
  /// Creates the screen.
  const JuzIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.juzIndexTitle)),
      body: AppContentFrame(
        child: JuzIndexBody(
          onSelect: (entry) => context.push(
            quranReaderPath(
              surah: entry.surahId,
              ayah: entry.numberInSurah,
            ),
          ),
        ),
      ),
    );
  }
}
