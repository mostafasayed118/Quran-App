import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pack_downloader.dart';
import 'ayah_sheet_state.dart';

/// Resolves the INSTALLED tafsir + translation context for one ayah.
///
/// Ephemeral: created per sheet-open, closed when the sheet dismisses.
/// Cataloged-but-uninstalled packs have no registry row, so they surface
/// as absent by construction; rows with a missing file read as absent
/// (PackDownloader null semantics), never throwing upward.
class AyahSheetCubit extends Cubit<AyahSheetState> {
  /// Creates the cubit for one ayah and starts resolving its packs.
  ///
  /// [surah] is the surah id and [ayah] the ayah number inside it; the
  /// resolution is fire-and-forget and ends in ready or failed.
  AyahSheetCubit({
    required PackDownloader downloader,
    required int surah,
    required int ayah,
  })  : _downloader = downloader,
        _surah = surah,
        _ayah = ayah,
        super(const AyahSheetState.loading()) {
    _load();
  }

  final PackDownloader _downloader;
  final int _surah;
  final int _ayah;

  Future<void> _load() async {
    try {
      final rows = await _downloader.installedPacks();
      final tafsirs = await Future.wait([
        for (final row in rows)
          if (row.kind == 'tafsir') _tafsirEntry(row.packId, row.title),
      ]);
      final translations = await Future.wait([
        for (final row in rows)
          if (row.kind == 'translation')
            _translationEntry(row.packId, row.title),
      ]);
      if (isClosed) return;
      emit(AyahSheetState.ready(
        tafsirEntries: [
          for (final entry in tafsirs)
            if (entry != null) entry,
        ],
        translationEntries: [
          for (final entry in translations)
            if (entry != null) entry,
        ],
      ));
    } on Object catch (error, stackTrace) {
      dev.log('ayah sheet load failed',
          name: 'quran_yahdi/ayah_sheet', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const AyahSheetState.failed());
      return;
    }
  }

  Future<AyahSheetEntry?> _tafsirEntry(String packId, String title) async {
    final text = await _downloader.tafsirFor(packId, _surah, _ayah);
    return text == null ? null : (title: title, text: text);
  }

  Future<AyahSheetEntry?> _translationEntry(String packId, String title) async {
    final text = await _downloader.translationFor(packId, _surah, _ayah);
    return text == null ? null : (title: title, text: text);
  }
}
