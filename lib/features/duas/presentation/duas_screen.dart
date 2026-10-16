import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../l10n/app_localizations.dart';
import 'duas_cubit.dart';
import 'duas_state.dart';

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.duasAndRuqyah)),
      body: BlocBuilder<DuasCubit, DuasState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<DuasTab>(
                      segments: [
                        ButtonSegment(
                          value: DuasTab.duas,
                          label: Text(loc.duasTab),
                          icon: const Icon(Icons.volunteer_activism),
                        ),
                        ButtonSegment(
                          value: DuasTab.ruqyah,
                          label: Text(loc.ruqyahTab),
                          icon: const Icon(Icons.healing),
                        ),
                      ],
                      selected: {
                        state is RuqyahInView
                            ? DuasTab.ruqyah
                            : DuasTab.duas,
                      },
                      onSelectionChanged: (selection) => context
                          .read<DuasCubit>()
                          .selectTab(selection.first),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                DuasLoading() => const LoadingView(),
                DuasInView() => const _DuasView(),
                RuqyahInView() => const _RuqyahView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DuasView extends StatelessWidget {
  const _DuasView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuasCubit, DuasState>(
      builder: (context, state) {
        final view = state as DuasInView;
        return Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final category in view.categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: view.selectedCategory == category,
                        onSelected: (_) => context
                            .read<DuasCubit>()
                            .selectCategory(
                              view.selectedCategory == category
                                  ? null
                                  : category,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: view.entries.length,
                itemBuilder: (context, i) {
                  final entry = view.entries[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            entry.text,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: QuranFonts.meQuran,
                              fontSize: 17,
                              height: 1.8,
                            ),
                          ),
                          if (entry.count > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '×${entry.count.toArabicIndic}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (entry.reference != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                entry.reference!,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RuqyahView extends StatelessWidget {
  const _RuqyahView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuasCubit, DuasState>(
      builder: (context, state) {
        final view = state as RuqyahInView;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: view.entries.length,
          itemBuilder: (context, i) {
            final entry = view.entries[i];
            final colors = Theme.of(context).colorScheme;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (entry.citation != null)
                      Text(
                        entry.citation!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.secondary,
                        ),
                      ),
                    Text(
                      entry.displayText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: entry.isQuran
                            ? QuranFonts.quran
                            : QuranFonts.meQuran,
                        fontSize: 18,
                        height: entry.isQuran ? 2.0 : 1.8,
                      ),
                    ),
                    if (entry.count > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '×${entry.count.toArabicIndic}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (entry.reference != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          entry.reference!,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
