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
    final rows = await _downloader.installedPacks();
    final tafsirs = <AyahSheetEntry>[];
    final translations = <AyahSheetEntry>[];
    for (final row in rows) {
      if (row.kind == 'tafsir') {
        final text = await _downloader.tafsirFor(row.packId, _surah, _ayah);
        if (text != null) {
          tafsirs.add((title: row.title, text: text));
        }
      } else if (row.kind == 'translation') {
        final text =
            await _downloader.translationFor(row.packId, _surah, _ayah);
        if (text != null) {
          translations.add((title: row.title, text: text));
        }
      }
      // hadith rows never feed the ayah sheet.
    }
    if (isClosed) return;
    emit(AyahSheetState.ready(
      tafsirEntries: tafsirs,
      translationEntries: translations,
    ));
  }
}
