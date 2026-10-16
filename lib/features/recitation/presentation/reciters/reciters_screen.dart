import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/ar_badge.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/error_strip.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/section_header.dart';
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
          RecitersLoading() => const LoadingView(),
          RecitersError(:final message) => _errorPane(loc, message, 'reciters'),
          RecitersReady(:final reciters, :final dataError) => Column(
              children: [
                if (dataError != null)
                  ErrorStrip(
                    dataError,
                    icon: Icons.wifi_off,
                    onDismiss: () =>
                        context.read<RecitersCubit>().clearDataError(),
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

Widget _errorPane(AppLocalizations loc, String message, String source) {
  dev.log(message, name: 'quran_yahdi/$source');
  return ErrorView(loc.genericError);
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
        children.add(SectionHeader(title: loc.featured));
        featuredHeaderDone = true;
      }
      if (!featured && !allHeaderDone) {
        children.add(SectionHeader(title: loc.allReciters));
        allHeaderDone = true;
      }
      children.add(_ReciterRow(reciter: row));
    }
    return ListView(children: children);
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
        ? loc.unknownInitial
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
