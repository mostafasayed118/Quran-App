import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import 'hadith_cubit.dart';
import 'hadith_state.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const _HadithTitle()),
      body: BlocBuilder<HadithCubit, HadithState>(
        builder: (context, state) {
          final Widget content = switch (state) {
            HadithLoading() => const Center(child: CircularProgressIndicator()),
            HadithError() => errorPane(loc),
            final HadithReady ready => Column(
                children: [
                  Expanded(child: _HadithVerses(ready: ready)),
                  _HadithPager(ready: ready),
                ],
              ),
          };
          return content;
        },
      ),
    );
  }
}

class _HadithTitle extends StatelessWidget {
  const _HadithTitle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HadithCubit, HadithState>(
      buildWhen: (a, b) => a is HadithLoading || b is HadithReady,
      builder: (context, state) {
        final s = state;
        final title = s is HadithReady ? s.packTitle : '';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
            if (s is HadithReady && s.language.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                s.language.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.goldText(context),
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HadithVerses extends StatelessWidget {
  const _HadithVerses({required this.ready});

  final HadithReady ready;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: ready.items.length,
      itemBuilder: (context, index) {
        final (number, text) = ready.items[index];
        final rtl = ready.language == 'ar';
        if (text.isEmpty) {
          return const SizedBox.shrink();
        }
        return _HadithVerseRow(number: number, text: text, rtl: rtl);
      },
    );
  }
}

class _HadithVerseRow extends StatelessWidget {
  const _HadithVerseRow({
    required this.number,
    required this.text,
    required this.rtl,
  });

  final int number;
  final String text;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Text(
              number.toArabicIndic,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.8),
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithPager extends StatelessWidget {
  const _HadithPager({required this.ready});

  final HadithReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed:
                  ready.offset > 0 ? context.read<HadithCubit>().prev : null,
              child: Text(loc.hadithPrev),
            ),
            TextButton(
              onPressed:
                  ready.hasMore ? context.read<HadithCubit>().next : null,
              child: Text(loc.hadithNext),
            ),
          ],
        ),
      ),
    );
  }
}
