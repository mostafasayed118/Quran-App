import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/db/app_database.dart';
import '../data/catalog_repository.dart';
import '../data/library_catalog.dart';
import '../data/pack_downloader.dart';
import 'library_state.dart';

/// Library hub: catalog browse + install progress + installed management.
///
/// In-flight progress is transient cubit state only (by design — InstalledPacks
/// row presence IS the installed status, no drift columns).
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({
    required CatalogRepository catalog,
    required PackDownloader downloader,
  })  : _catalog = catalog,
        _downloader = downloader,
        super(const LibraryState.loading()) {
    unawaited(load());
  }

  final CatalogRepository _catalog;
  final PackDownloader _downloader;

  Future<void> load() async {
    final List<LibraryPackInfo> packs;
    final List<InstalledPack> rows;
    try {
      packs = await _catalog.packs();
      rows = await _downloader.installedPacks();
    } on Object catch (error) {
      if (isClosed) return;
      emit(LibraryState.failed(message: error.toString()));
      return;
    }
    if (isClosed) return;
    emit(LibraryState.ready(
      packs: packs,
      installed: {for (final row in rows) row.packId},
    ));
  }

  Future<void> install(LibraryPackInfo pack) async {
    if (isClosed || _inFlight(pack.id)) return;
    final expected = (pack.approxSizeMb * 1024 * 1024).round();
    if (state is LibraryReady) {
      final ready = state as LibraryReady;
      emit(ready.copyWith(
        failed: {...ready.failed}..remove(pack.id),
        progress: {...ready.progress, pack.id: (0, expected)},
      ));
    }
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
    } on Object {
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

  Future<void> uninstall(String packId) async {
    await _downloader.uninstall(packId);
    if (isClosed) return;
    final ready = state;
    if (ready is! LibraryReady) return;
    emit(ready.copyWith(installed: {...ready.installed}..remove(packId)));
  }

  void dismissFailure(String packId) {
    final ready = state;
    if (ready is! LibraryReady) return;
    emit(ready.copyWith(failed: {...ready.failed}..remove(packId)));
  }

  Future<void> retry(String packId) async {
    final pack = await _catalog.byId(packId);
    if (pack == null) return;
    await install(pack);
  }

  bool _inFlight(String packId) {
    final ready = state;
    return ready is LibraryReady && ready.progress.containsKey(packId);
  }
}
