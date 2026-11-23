import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:quran_yahdi/core/domain/ayah_ref.dart';
import 'package:quran_yahdi/core/utils/arabic_date.dart';
import 'package:quran_yahdi/core/widgets/app_content_frame.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'feelings_cubit.dart';
import 'feelings_state.dart';

/// Q46 — saved verses, newest first.
class SavedVersesScreen extends StatelessWidget {
  const SavedVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.feelingsSavedButton)),
      body: AppContentFrame(
        child: BlocBuilder<SavedVersesCubit, SavedVersesState>(
          builder: (context, state) => switch (state) {
            SavedVersesLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SavedVersesReady(:final verses) =>
              verses.isEmpty
                  ? Center(child: Text(loc.feelingsEmpty))
                  : ListView.builder(
                      itemCount: verses.length,
                      itemBuilder: (context, index) {
                        final row = verses[index];
                        return ListTile(
                          title: FutureBuilder<AyahRef?>(
                            future: context.read<SavedVersesCubit>().ayahRef(
                              row.ayahId,
                            ),
                            builder: (context, snap) {
                              final ref = snap.data;
                              final label = ref == null
                                  ? _feelingName(loc, row.feeling.value)
                                  : '${_feelingName(loc, row.feeling.value)}'
                                        ' · ${ref.surahId}:${ref.numberInSurah}';
                              return Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          subtitle: Text(formatArabicDate(row.createdAt)),
                          trailing: IconButton(
                            tooltip: loc.feelingsDelete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                context.read<SavedVersesCubit>().delete(row.id),
                          ),
                        );
                      },
                    ),
          },
        ),
      ),
    );
  }
}

String _feelingName(AppLocalizations loc, String key) => switch (key) {
  'qalaq' => loc.feelingQalaq,
  'huzn' => loc.feelingHuzn,
  'wahda' => loc.feelingWahda,
  'hayra' => loc.feelingHayra,
  'khawf' => loc.feelingKhawf,
  'ghadab' => loc.feelingGhadab,
  'imtinam' => loc.feelingImtinam,
  _ => loc.feelingAmal,
};
