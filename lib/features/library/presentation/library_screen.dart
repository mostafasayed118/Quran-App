import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/insets.dart';
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
      buildWhen: _rebuildRoot,
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
                            _PackList(packs: ready.packsWhere(kind)),
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

/// Root rebuild gate: an install reports progress per 1 % step, and rebuilding
/// the scaffold + tab bar + both lists on every tick is wasted work — the
/// progress itself is read per row by [_PackRow]'s [BlocSelector].
///
/// Structural transitions still rebuild the root: the state variant, the pack
/// catalog, the failure set, and the empty/non-empty flip of
/// [LibraryReady.progress] (the failure strip is only shown while no download
/// is in flight, so that flip changes the layout).
bool _rebuildRoot(LibraryState previous, LibraryState current) {
  return switch ((previous, current)) {
    (LibraryLoading(), LibraryLoading()) => false,
    (LibraryFailed(), LibraryFailed()) => false,
    (final LibraryReady before, final LibraryReady after) =>
      _rootChanged(before, after),
    _ => true,
  };
}

bool _rootChanged(LibraryReady before, LibraryReady after) {
  if (before.progress.isEmpty != after.progress.isEmpty) return true;
  if (before.failed.length != after.failed.length ||
      !after.failed.containsAll(before.failed)) {
    return true;
  }
  if (identical(before.packs, after.packs)) return false;
  if (before.packs.length != after.packs.length) return true;
  for (var i = 0; i < before.packs.length; i++) {
    final old = before.packs[i];
    final updated = after.packs[i];
    if (old.id != updated.id || old.kind != updated.kind) return true;
  }
  return false;
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
  const _PackList({required this.packs});

  final List<LibraryPackInfo> packs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: appScrollPadding(
        context,
        const EdgeInsets.only(bottom: AppSpacing.md),
      ),
      itemCount: packs.length,
      itemBuilder: (context, index) => _PackRow(pack: packs[index]),
    );
  }
}

/// The per-row slice of [LibraryReady] the trailing area reads.
///
/// A value record on purpose: [BlocSelector] compares it with `==`, so a
/// progress tick for one pack rebuilds that pack's row and nothing else.
typedef _PackRowStatus = ({bool installed, (int, int)? progress});

class _PackRow extends StatelessWidget {
  const _PackRow({required this.pack});

  final LibraryPackInfo pack;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final subtitle = loc.libraryPackMeta(
      pack.approxSizeMb.toString().toArabicIndicDigits,
      pack.version,
    );

    return ListTile(
      title: Text(
        pack.titleAr,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(loc.libraryPackSubtitle(subtitle, pack.titleEn)),
      trailing: BlocSelector<LibraryCubit, LibraryState, _PackRowStatus>(
        selector: _statusOf,
        builder: (context, status) => _trailing(context, loc, status),
      ),
    );
  }

  _PackRowStatus _statusOf(LibraryState state) => switch (state) {
        final LibraryReady ready => (
            installed: ready.installed.contains(pack.id),
            progress: ready.progress[pack.id],
          ),
        _ => (installed: false, progress: null),
      };

  Widget _trailing(
    BuildContext context,
    AppLocalizations loc,
    _PackRowStatus status,
  ) {
    final cubit = context.read<LibraryCubit>();
    final progress = status.progress;
    final installed = status.installed;

    final Widget action;
    if (progress != null) {
      final (received, total) = progress;
      action = DownloadProgressLabel(
        received: received,
        total: total,
        format: (r, t) => loc.downloadProgressOfTotal(
          formatMegabytes(r).toArabicIndicDigits,
          formatMegabytes(t).toArabicIndicDigits,
        ),
      );
    } else if (installed) {
      action = IconButton(
        tooltip: loc.libraryDelete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(context, cubit, loc),
      );
    } else {
      action = FilledButton(
        onPressed: () => cubit.install(pack),
        child: Text(loc.libraryInstall),
      );
    }

    return Row(
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
        action,
      ],
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
