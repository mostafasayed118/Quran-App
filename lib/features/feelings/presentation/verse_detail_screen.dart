import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/app_radius.dart';
import 'package:quran_yahdi/core/theme/app_spacing.dart';
import 'package:quran_yahdi/core/theme/app_type.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/core/widgets/app_content_frame.dart';
import 'package:quran_yahdi/core/widgets/error_pane.dart';
import 'package:quran_yahdi/core/widgets/loading_and_error_views.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/feeling.dart';
import 'feelings_cubit.dart';
import 'feelings_reference.dart';
import 'feelings_state.dart';

/// Q45 — full verse with save/share/listen/copy and next-verse navigation.
class VerseDetailScreen extends StatelessWidget {
  const VerseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.feelingsTadabburScreenTitle)),
      body: AppContentFrame(
        child: BlocBuilder<VerseDetailCubit, VerseDetailState>(
          builder: (context, state) => switch (state) {
            VerseDetailLoading() => const LoadingView(),
            VerseDetailFailed() => errorPane(
              loc,
              onRetry: context.read<VerseDetailCubit>().start,
            ),
            VerseDetailReady(:final verse, :final isSaved) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.mushafCardTop,
                        AppColors.mushafCardBottom,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Text(
                        feelingMetadata(context, verse),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.mushafCardAccent),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        verse.fullText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.mushafCardInk,
                          fontFamily: 'HafsSmart',
                        ),
                      ),
                    ],
                  ),
                ),
                if (verse.verse.surah == 13 && verse.verse.ayah == 28) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    loc.feelingsTadabburTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(loc.feelingsTadabburCopy),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _action(
                      icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                      label: isSaved ? loc.feelingsSaved : loc.feelingsSave,
                      onPressed: context.read<VerseDetailCubit>().toggleSave,
                    ),
                    _action(
                      icon: Icons.share,
                      label: loc.feelingsShare,
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${verse.fullText} — '
                              '${feelingReference(context, verse)}',
                        ),
                      ),
                    ),
                    _action(
                      icon: Icons.headphones,
                      label: loc.feelingsListen,
                      onPressed: context.read<VerseDetailCubit>().listen,
                    ),
                    _action(
                      icon: Icons.content_copy,
                      label: loc.feelingsCopy,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${verse.fullText} — '
                                '${feelingReference(context, verse)}',
                          ),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.feelingsCopied)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_hasNext(verse.feeling, verse.verse))
                  FilledButton.icon(
                    onPressed: () {
                      final feeling = FeelingsCatalog.byKey(verse.feeling)!;
                      final index = feeling.verses.indexOf(verse.verse);
                      final next = feeling.verses[index + 1];
                      context.push(
                        feelingsVersePath(
                          next.surah,
                          next.ayah,
                          verse.feeling.value,
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(loc.feelingsNextVerse),
                  ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

bool _hasNext(FeelingKey key, FeelingVerse verse) {
  final feeling = FeelingsCatalog.byKey(key);
  if (feeling == null) return false;
  final index = feeling.verses.indexOf(verse);
  return index >= 0 && index < feeling.verses.length - 1;
}

Widget _action({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(icon: Icon(icon), onPressed: onPressed),
    Text(label, style: const TextStyle(fontSize: AppType.micro)),
  ],
);
