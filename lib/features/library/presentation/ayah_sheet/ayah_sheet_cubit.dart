import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/pack_downloader.dart';
import 'ayah_sheet_state.dart';

/// Resolves the INSTALLED tafsir + translation context for one ayah.
///
/// Ephemeral: created per sheet-open, closed when the sheet dismisses.
/// Cataloged-but-uninstalled packs have no registry row, so they surface
/// as absent by construction; rows with a missing file read as absent
/// (PackDownloader null semantics), never throwing upward.
class AyahSheetCubit extends Cubit<AyahSheetState> {
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
          if (row.kind == 'tafsir') _tafsirEntry(row),
      ]);
      final translations = await Future.wait([
        for (final row in rows)
          if (row.kind == 'translation') _translationEntry(row),
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
    } catch (error) {
      if (isClosed) return;
      emit(AyahSheetState.error(message: error.toString()));
      return;
    }
  }

  Future<AyahSheetEntry?> _tafsirEntry(InstalledPack row) async {
    final text = await _downloader.tafsirFor(row.packId, _surah, _ayah);
    return text == null ? null : (title: row.title, text: text);
  }

  Future<AyahSheetEntry?> _translationEntry(InstalledPack row) async {
    final text = await _downloader.translationFor(row.packId, _surah, _ayah);
    return text == null ? null : (title: row.title, text: text);
  }
}
