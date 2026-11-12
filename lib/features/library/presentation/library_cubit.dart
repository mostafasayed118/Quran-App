import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../data/catalog_repository.dart';
import '../data/library_catalog.dart';
import '../data/pack_downloader.dart';
import 'library_state.dart';

/// Library hub: catalog browse + install progress + installed management.
///
/// In-flight progress is transient cubit state only (by design — InstalledPacks
/// row presence IS the installed status, no drift columns).
class LibraryCubit extends Cubit<LibraryState> {
  /// Creates the cubit; the constructor is side-effect free and does no
  /// work — [start] performs the first load.
  LibraryCubit({
    required CatalogRepository catalog,
    required PackDownloader downloader,
  })  : _catalog = catalog,
        _downloader = downloader,
        super(const LibraryState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() {
    _progressSub ??= _downloader.progressStream.listen(_onProgress);
    return load();
  }

  final CatalogRepository _catalog;
  final PackDownloader _downloader;
  StreamSubscription<Map<String, (int, int)>>? _progressSub;

  void _onProgress(Map<String, (int, int)> progress) {
    if (isClosed) return;
    final current = state;
    if (current is! LibraryReady) return;
    emit(current.copyWith(progress: progress));
  }

  /// Loads the catalog and the installed pack ids and emits them.
  ///
  /// A failure emits the failed state (the error is logged, never raised as
  /// an unhandled async error).
  Future<void> load() async {
    final List<LibraryPackInfo> catalogPacks;
    final List<LibraryPackInfo> orphans;
    final Set<String> installed;
    try {
      catalogPacks = await _catalog.packs();
      final rows = await _downloader.installedPacks();
      final catalogIds = {for (final pack in catalogPacks) pack.id};
      // An installed row whose catalog entry vanished must stay visible:
      // hiding it also hid the only delete affordance for its file. Built
      // here so the presentation layer never names the drift row type.
      orphans = <LibraryPackInfo>[
        for (final row in rows)
          if (!catalogIds.contains(row.packId))
            LibraryPackInfo(
              id: row.packId,
              kind: LibraryPackKind.values
                      .where((kind) => kind.name == row.kind)
                      .firstOrNull ??
                  LibraryPackKind.tafsir,
              language: row.language,
              titleAr: row.title,
              titleEn: row.title,
              approxSizeMb: row.sizeMb,
              version: row.version,
              orphan: true,
            ),
      ];
      installed = {for (final row in rows) row.packId};
    } on Object catch (error, stackTrace) {
      appLog('library load failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const LibraryState.failed());
      return;
    }
    if (isClosed) return;
    emit(LibraryState.ready(
      packs: [...catalogPacks, ...orphans],
      installed: installed,
      // A route that re-enters while an app-scoped install is still running
      // must show the current bytes, not a reset 0 %.
      progress: {..._downloader.progress},
    ));
  }

  /// Downloads and installs [pack], reporting progress on the state.
  ///
  /// A pack already in flight is ignored; a failure is recorded per pack id
  /// (the failed set) instead of failing the whole screen.
  Future<void> install(LibraryPackInfo pack) async {
    if (isClosed || _inFlight(pack.id)) return;
    final current = state;
    if (current is! LibraryReady) return;
    final expected = (pack.approxSizeMb * 1024 * 1024).round();
    emit(current.copyWith(
      failed: {...current.failed}..remove(pack.id),
      progress: {...current.progress, pack.id: (0, expected)},
    ));
    try {
      await _downloader.install(pack, onProgress: (received, total) {
        if (isClosed) return;
        final current = state;
        if (current is! LibraryReady) return;
        emit(current.copyWith(progress: {
          ...current.progress,
          pack.id: (received, total),
        }));
      });
      if (isClosed) return;
      final ready = state;
      if (ready is! LibraryReady) return;
      emit(ready.copyWith(
        installed: {...ready.installed, pack.id},
        progress: {...ready.progress}..remove(pack.id),
      ));
      onInstalled(pack.id);
    } on Object catch (error, stackTrace) {
      appLog('library install failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      final ready = state;
      if (ready is! LibraryReady) return;
      emit(ready.copyWith(
        failed: {...ready.failed, pack.id},
        progress: {...ready.progress}..remove(pack.id),
      ));
    }
  }

  /// Hook for subclasses/tests that need the freshly-installed pack id.
  void onInstalled(String packId) {}

  @override
  Future<void> close() async {
    await _progressSub?.cancel();
    _progressSub = null;
    return super.close();
  }

  /// Removes the installed pack [packId] and drops it from the installed set.
  ///
  /// A failure records the pack id in the failed set.
  Future<void> uninstall(String packId) async {
    try {
      await _downloader.uninstall(packId);
    } on Object catch (error, stackTrace) {
      appLog('library uninstall failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      final ready = state;
      if (ready is! LibraryReady) return;
      emit(ready.copyWith(failed: {...ready.failed, packId}));
      return;
    }
    if (isClosed) return;
    final ready = state;
    if (ready is! LibraryReady) return;
    final wasOrphan =
        ready.packs.any((pack) => pack.id == packId && pack.orphan);
    emit(ready.copyWith(
      installed: {...ready.installed}..remove(packId),
      // An orphan has no catalog entry to reinstall from: drop its row too,
      // otherwise the row would offer an install that cannot work.
      packs: wasOrphan
          ? [
              for (final pack in ready.packs)
                if (pack.id != packId) pack,
            ]
          : ready.packs,
    ));
  }

  /// Clears the failure recorded for [packId] (the user dismissed it).
  void dismissFailure(String packId) {
    if (isClosed) return;
    final ready = state;
    if (ready is! LibraryReady) return;
    emit(ready.copyWith(failed: {...ready.failed}..remove(packId)));
  }

  /// Re-runs the failed operation for [packId].
  ///
  /// An install failure re-installs; an uninstall failure retries the delete.
  /// The pack is still in [LibraryReady.installed] when the delete failed.
  Future<void> retry(String packId) async {
    final ready = state;
    if (ready is LibraryReady && ready.installed.contains(packId)) {
      await uninstall(packId);
      return;
    }
    try {
      final pack = await _catalog.byId(packId);
      if (pack == null) return;
      await install(pack);
    } on Object catch (error, stackTrace) {
      appLog('library retry failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
    }
  }

  bool _inFlight(String packId) {
    final ready = state;
    return ready is LibraryReady && ready.progress.containsKey(packId);
  }
}
