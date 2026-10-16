import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/download_progress.dart';
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
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(loc.library),
              bottom: TabBar(
                tabs: [
                  Tab(text: loc.tafsirTab),
                  Tab(text: loc.translationsTab),
                  Tab(text: loc.hadithTab),
                ],
              ),
            ),
            body: switch (state) {
              LibraryLoading() => const LoadingView(),
              final LibraryReady ready => Column(
                  children: [
                    if (ready.failed.isNotEmpty && ready.progress.isEmpty)
                      _FailureStrip(
                        packs: ready.packs,
                        failed: ready.failed,
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _PackList(
                            packs: ready
                                .packsWhere(LibraryPackKind.tafsir),
                            ready: ready,
                          ),
                          _PackList(
                            packs: ready
                                .packsWhere(LibraryPackKind.translation),
                            ready: ready,
                          ),
                          _PackList(
                            packs: ready.packsWhere(LibraryPackKind.hadith),
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
}

extension on LibraryReady {
  List<LibraryPackInfo> packsWhere(LibraryPackKind kind) =>
      [for (final pack in packs) if (pack.kind == kind) pack];
}

class _FailureStrip extends StatelessWidget {
  const _FailureStrip({required this.packs, required this.failed});

  final List<LibraryPackInfo> packs;
  final Set<String> failed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<LibraryCubit>();
    final packId = failed.first;
    final pack = packs.where((p) => p.id == packId).firstOrNull;
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: SafeArea(
        top: false,
        child: ListTile(
          dense: true,
          title: Text(
            '${loc.libraryFailed}${pack != null ? ' — ${pack.titleAr}' : ''}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => cubit.retry(packId),
                child: Text(loc.libraryRetry),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => cubit.dismissFailure(packId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackList extends StatelessWidget {
  const _PackList({required this.packs, required this.ready});

  final List<LibraryPackInfo> packs;
  final LibraryReady ready;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
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
    final colors = Theme.of(context).colorScheme;
    final progress = ready.progress[pack.id];
    final installed = ready.installed.contains(pack.id);
    final subtitle =
        '${pack.approxSizeMb.toString().toArabicIndicDigits} MB · ${pack.version}';

    final Widget trailing;
    if (progress != null) {
      final (received, total) = progress;
      trailing = DownloadProgressLabel(
        received: received,
        total: total,
        format: (r, t) =>
            '${_mb(r).toArabicIndicDigits} / ${_mb(t).toArabicIndicDigits} MB',
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
      subtitle: Text('$subtitle · ${pack.titleEn}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (installed && progress == null)
            Text(
              loc.libraryInstalled,
              style: TextStyle(color: colors.secondary, fontSize: 12),
            ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  static String _mb(int bytes) {
    final v = bytes / (1024 * 1024);
    return v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  Future<void> _confirmDelete(
      BuildContext context, LibraryCubit cubit, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.libraryDelete),
        content: Text(pack.titleAr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.libraryDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.uninstall(pack.id);
    }
  }
}
