import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/pack_downloader.dart';
import 'ayah_sheet_cubit.dart';
import 'ayah_sheet_state.dart';

/// Bottom sheet reading the INSTALLED tafsir/translation of one ayah;
/// empty states route to /library. Resolves its deps via getIt so the
/// reader route stays untouched ([downloader] is a widget-test seam).
class LibrarySheet extends StatelessWidget {
  const LibrarySheet({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.ayah,
    this.downloader,
  });

  final int surahId;
  final String surahName;
  final int ayah;
  final PackDownloader? downloader;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AyahSheetCubit>(
      create: (_) => AyahSheetCubit(
        downloader: downloader ?? getIt<PackDownloader>(),
        surah: surahId,
        ayah: ayah,
      ),
      child: _AyahSheetView(surahName: surahName, ayah: ayah),
    );
  }
}

class _AyahSheetView extends StatelessWidget {
  const _AyahSheetView({required this.surahName, required this.ayah});

  final String surahName;
  final int ayah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return BlocBuilder<AyahSheetCubit, AyahSheetState>(
      builder: (context, state) {
        final Widget content = switch (state) {
          AyahSheetLoading() =>
            const Center(child: CircularProgressIndicator()),
          final AyahSheetReady ready => DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            loc.ayahSheetTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          '$surahName ﴿${ayah.toArabicIndic}﴾',
                          style: TextStyle(
                            fontFamily: QuranFonts.meQuran,
                            fontSize: 15,
                            color: colors.secondary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    tabs: [
                      Tab(text: loc.ayahSheetTafsir),
                      Tab(text: loc.ayahSheetTranslation),
                    ],
                  ),
                  Flexible(
                    child: TabBarView(
                      children: [
                        _SheetPane(entries: ready.tafsirEntries),
                        _SheetPane(entries: ready.translationEntries),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        };
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        );
      },
    );
  }
}

class _SheetPane extends StatelessWidget {
  const _SheetPane({required this.entries});

  final List<AyahSheetEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final loc = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.libraryEmptyHint),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/library');
                },
                child: Text(loc.library),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                entry.title,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 4),
              Text(
                entry.text,
                style: const TextStyle(fontSize: 16, height: 1.9),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        );
      },
    );
  }
}
