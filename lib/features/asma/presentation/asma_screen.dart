import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/asma_repository.dart';
import 'asma_cubit.dart';
import 'asma_state.dart';

class AsmaScreen extends StatelessWidget {
  const AsmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.asmaUlHusna)),
      body: BlocBuilder<AsmaCubit, AsmaState>(
        builder: (context, state) => switch (state) {
          AsmaLoading() => const LoadingView(),
          AsmaFailed() => errorPane(loc, 'asma load failed', 'asma'),
          AsmaReady(:final names) when names.isEmpty =>
            EmptyState(loc.noResults),
          AsmaReady(:final names, :final selected) => Stack(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: names.length,
                  itemBuilder: (context, i) {
                    final name = names[i];
                    final colors = Theme.of(context).colorScheme;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.read<AsmaCubit>().select(name),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name.n.toArabicIndic,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name.nameAr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: QuranFonts.meQuran,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                name.nameEn,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.mutedFootnote(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (selected != null) _NameSheet(name: selected),
              ],
            ),
        },
      ),
    );
  }
}

class _NameSheet extends StatelessWidget {
  const _NameSheet({required this.name});

  final AsmaName name;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Card(
        margin: const EdgeInsets.all(12),
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      loc.namePosition(name.n.toArabicIndic),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: loc.clearSelection,
                    icon: const Icon(Icons.close),
                    onPressed: () => context.read<AsmaCubit>().select(null),
                  ),
                ],
              ),
              Text(
                name.nameAr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.nameEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name.meaningAr,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name.meaningEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
