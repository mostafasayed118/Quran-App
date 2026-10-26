import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/pack_downloader.dart';
import 'ayah_sheet_cubit.dart';
import 'ayah_sheet_state.dart';

/// Bottom sheet reading the INSTALLED tafsir/translation of one ayah;
/// empty states route to /library. [downloader] is a widget-test seam:
/// production callers omit it and the registered singleton is resolved here,
/// so the reader presentation never depends on the library data layer.
class AyahSheet extends StatefulWidget {
  const AyahSheet({
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
  State<AyahSheet> createState() => _AyahSheetState();
}

class _AyahSheetState extends State<AyahSheet> {
  late final AyahSheetCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Created outside build so the pack reads start in the mount lifecycle,
    // not inside a frame's build. The container is resolved through get_it
    // directly: a feature may not import the app layer (the composition
    // root), and the compatibility shim exists for the frozen suite only.
    _cubit = AyahSheetCubit(
      downloader: widget.downloader ?? GetIt.instance<PackDownloader>(),
      surah: widget.surahId,
      ayah: widget.ayah,
    );
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AyahSheetCubit>.value(
      value: _cubit,
      child: _AyahSheetView(surahName: widget.surahName, ayah: widget.ayah),
    );
  }
}

/// The sheet's former name, kept ONLY as a compatibility alias for the
/// frozen suite (the widget test imports this file by path and uses the old
/// name). Production code calls [AyahSheet].
typedef LibrarySheet = AyahSheet;

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
          AyahSheetLoading() => const LoadingView(),
          AyahSheetFailed() => errorPane(loc),
          final AyahSheetReady ready => _SheetBody(
              surahName: surahName,
              ayah: ayah,
              ready: ready,
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

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.surahName,
    required this.ayah,
    required this.ready,
  });

  final String surahName;
  final int ayah;
  final AyahSheetReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(surahName: surahName, ayah: ayah),
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
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.surahName, required this.ayah});

  final String surahName;
  final int ayah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 14, AppSpacing.lg, AppSpacing.xs),
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
            '$surahName ${loc.ornateBrackets(ayah.toArabicIndic)}',
            style: TextStyle(
              fontFamily: QuranFonts.meQuran,
              fontSize: 15,
              color: AppTheme.goldText(context),
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
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
      return EmptyState(
        loc.libraryEmptyHint,
        actionLabel: loc.library,
        onAction: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.library);
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
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
              const SizedBox(height: AppSpacing.xs),
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
