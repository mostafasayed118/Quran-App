import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/download_progress.dart';
import '../../../core/widgets/error_pane.dart';
import '../../../core/widgets/error_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/library_catalog.dart';
import 'library_cubit.dart';
import 'library_state.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final loc = AppLocalizations.of(context);
        final kinds = switch (state) {
          LibraryReady(:final packs) => visibleLibraryKinds(packs),
          _ => _libraryKinds,
        };
        return DefaultTabController(
          length: kinds.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(loc.library),
              bottom: TabBar(
                tabs: [
                  for (final kind in kinds)
                    Tab(text: _libraryTabLabel(loc, kind)),
                ],
              ),
            ),
            body: switch (state) {
              LibraryLoading() => const LoadingView(),
              LibraryFailed() => errorPane(loc),
              final LibraryReady ready => Column(
                  children: [
                    if (ready.failed.isNotEmpty && ready.progress.isEmpty)
                      _failureStrip(context, ready),
                    Expanded(
                      child: TabBarView(
                        children: [
                          for (final kind in kinds)
                            _PackList(
                              packs: ready.packsWhere(kind),
                              ready: ready,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            },
          ),
        );
      },
    );
  }

  Widget _failureStrip(BuildContext context, LibraryReady ready) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<LibraryCubit>();
    final packId = ready.failed.first;
    final pack = ready.packs.where((p) => p.id == packId).firstOrNull;
    return ErrorStrip(
      pack == null
          ? loc.libraryFailed
          : loc.libraryFailedForPack(loc.libraryFailed, pack.titleAr),
      actionLabel: loc.libraryRetry,
      onRetry: () => cubit.retry(packId),
      onDismiss: () => cubit.dismissFailure(packId),
    );
  }
}

extension on LibraryReady {
  List<LibraryPackInfo> packsWhere(LibraryPackKind kind) => [
        for (final pack in packs)
          if (pack.kind == kind) pack
      ];
}

/// Fixed display order for the library tabs.
const List<LibraryPackKind> _libraryKinds = [
  LibraryPackKind.tafsir,
  LibraryPackKind.translation,
  LibraryPackKind.hadith,
];

/// The tabs that actually have packs, in display order.
///
/// A kind with no catalog entry is hidden instead of rendering a blank tab
/// (the unlicensed tafsir packs are withdrawn, so a fresh install has none).
/// An empty catalog falls back to the three tabs so the controller is never
/// zero-length.
List<LibraryPackKind> visibleLibraryKinds(Iterable<LibraryPackInfo> packs) {
  final present = {for (final pack in packs) pack.kind};
  final visible = [
    for (final kind in _libraryKinds)
      if (present.contains(kind)) kind,
  ];
  return visible.isEmpty ? _libraryKinds : visible;
}

String _libraryTabLabel(AppLocalizations loc, LibraryPackKind kind) =>
    switch (kind) {
      LibraryPackKind.tafsir => loc.tafsirTab,
      LibraryPackKind.translation => loc.translationsTab,
      LibraryPackKind.hadith => loc.hadithTab,
    };

class _PackList extends StatelessWidget {
  const _PackList({required this.packs, required this.ready});

  final List<LibraryPackInfo> packs;
  final LibraryReady ready;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: packs.length,
      itemBuilder: (context, index) =>
          _PackRow(pack: packs[index], ready: ready),
    );
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({required this.pack, required this.ready});

  final LibraryPackInfo pack;
  final LibraryReady ready;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<LibraryCubit>();
    final progress = ready.progress[pack.id];
    final installed = ready.installed.contains(pack.id);
    final subtitle = loc.libraryPackMeta(
      pack.approxSizeMb.toString().toArabicIndicDigits,
      pack.version,
    );

    final Widget trailing;
    if (progress != null) {
      final (received, total) = progress;
      trailing = DownloadProgressLabel(
        received: received,
        total: total,
        format: (r, t) => loc.downloadProgressOfTotal(
          formatMegabytes(r).toArabicIndicDigits,
          formatMegabytes(t).toArabicIndicDigits,
        ),
      );
    } else if (installed) {
      trailing = IconButton(
        tooltip: loc.libraryDelete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(context, cubit, loc),
      );
    } else {
      trailing = FilledButton(
        onPressed: () => cubit.install(pack),
        child: Text(loc.libraryInstall),
      );
    }

    return ListTile(
      title: Text(
        pack.titleAr,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(loc.libraryPackSubtitle(subtitle, pack.titleEn)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (installed && progress == null)
            Text(
              loc.libraryInstalled,
              style: TextStyle(color: AppTheme.goldText(context), fontSize: 12),
            ),
          if (installed && pack.kind == LibraryPackKind.hadith)
            IconButton(
              tooltip: loc.hadithRead,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => context.push(hadithBrowsePath(pack.id)),
            ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, LibraryCubit cubit, AppLocalizations loc) async {
    final confirmed = await confirmDeleteDialog(
      context,
      title: loc.libraryDelete,
      body: pack.titleAr,
    );
    if (confirmed) {
      await cubit.uninstall(pack.id);
    }
  }
}
