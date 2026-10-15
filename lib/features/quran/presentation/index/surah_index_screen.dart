import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'surah_index_cubit.dart';
import 'surah_index_state.dart';

class SurahIndexScreen extends StatelessWidget {
  const SurahIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.surahIndexTitle)),
      body: BlocBuilder<SurahIndexCubit, SurahIndexState>(
        builder: (context, state) => switch (state) {
          SurahIndexLoading() =>
            const Center(child: CircularProgressIndicator()),
          SurahIndexError(:final message) => Center(child: Text(message)),
          SurahIndexLoaded(:final surahs) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    onChanged: context.read<SurahIndexCubit>().setQuery,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: loc.searchSurahHint,
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: surahs.length,
                    itemBuilder: (context, i) => _SurahRow(surah: surahs[i]),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isMakkah = surah.revelationType == 'makkah';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      onTap: () {
        // W1b: navigate to the reader for this surah.
      },
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          '${surah.id}',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
      ),
      title: Text(
        surah.nameAr,
        style: const TextStyle(fontFamily: QuranFonts.meQuran, fontSize: 20),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        '${isMakkah ? loc.revelationMakkah : loc.revelationMadinah} · ${loc.ayatCount(surah.ayahCount)}',
        style: TextStyle(color: colors.onSurfaceVariant),
        textAlign: TextAlign.right,
      ),
      trailing: const Icon(Icons.chevron_left),
    );
  }
}
