import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/ar_badge.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/reciter_repository.dart';
import 'reciters_cubit.dart';
import 'reciters_state.dart';

class RecitersScreen extends StatelessWidget {
  const RecitersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recitationsTitle),
        actions: [
          IconButton(
            tooltip: loc.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RecitersCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<RecitersCubit, RecitersState>(
        builder: (context, state) => switch (state) {
          RecitersLoading() =>
            const Center(child: CircularProgressIndicator()),
          RecitersError(:final message) => Center(child: Text(message)),
          RecitersReady(:final reciters, :final dataError) => Column(
              children: [
                if (dataError != null)
                  Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.wifi_off, size: 18),
                      title: Text(
                        dataError,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: SearchField(
                    hint: loc.searchReciters,
                    onChanged: context.read<RecitersCubit>().setQuery,
                  ),
                ),
                Expanded(
                  child: reciters.isEmpty
                      ? Center(child: Text(loc.noReciters))
                      : _RecitersList(reciters: reciters),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _RecitersList extends StatelessWidget {
  const _RecitersList({required this.reciters});

  final List<ReciterRow> reciters;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final children = <Widget>[];
    var featuredHeaderDone = false;
    var allHeaderDone = false;
    for (final row in reciters) {
      final featured = isFeaturedReciterRow(row);
      if (featured && !featuredHeaderDone) {
        children.add(_SectionHeader(title: loc.featured));
        featuredHeaderDone = true;
      }
      if (!featured && !allHeaderDone) {
        children.add(_SectionHeader(title: loc.allReciters));
        allHeaderDone = true;
      }
      children.add(_ReciterRow(reciter: row));
    }
    return ListView(children: children);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ReciterRow extends StatelessWidget {
  const _ReciterRow({required this.reciter});

  final ReciterRow reciter;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trimmed = reciter.reciterName.trim();
    final initial = trimmed.isEmpty
        ? '؟'
        : String.fromCharCode(trimmed.runes.first);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      onTap: () => context.push(
          '/recitation/reciter?row=${Uri.encodeComponent(reciter.id)}'),
      leading: ArabicBadge(
        initial,
        textStyle: const TextStyle(fontSize: 16),
      ),
      title: Text(
        reciter.reciterName,
        style: const TextStyle(
          fontFamily: QuranFonts.ui,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        reciter.moshafName,
        style: TextStyle(color: colors.onSurfaceVariant),
        textAlign: TextAlign.right,
      ),
      trailing: Text(
        loc.surahCountLabel(reciter.surahTotal.toArabicIndic),
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}
