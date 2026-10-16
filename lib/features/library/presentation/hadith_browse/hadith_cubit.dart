import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/pack_downloader.dart';
import 'hadith_state.dart';

/// Pages through an INSTALLED hadith pack with a fixed page size.
class HadithCubit extends Cubit<HadithState> {
  HadithCubit({
    required PackDownloader downloader,
    required String packId,
  })  : _downloader = downloader,
        _packId = packId,
        super(const HadithState.loading()) {
    _load(0);
  }

  static const int pageSize = 10;

  final PackDownloader _downloader;
  final String _packId;

  Future<void> _load(int offset) async {
    InstalledPack? row;
    List<(int, String)> items;
    var hasMore = false;
    try {
      final rows = await _downloader.installedPacks();
      row = rows.where((r) => r.packId == _packId).firstOrNull;
      (items, hasMore) =
          await _downloader.hadithPage(_packId, offset, pageSize);
    } catch (error) {
      if (isClosed) return;
      emit(HadithState.error(message: error.toString()));
      return;
    }
    if (isClosed) return;
    emit(HadithState.ready(
      packTitle: row?.title ?? _packId,
      language: row?.language ?? '',
      items: items,
      offset: offset,
      hasMore: hasMore,
    ));
  }

  Future<void> next() {
    final s = state;
    if (s is! HadithReady || !s.hasMore) return Future.value();
    return _load(s.offset + pageSize);
  }

  Future<void> prev() {
    final s = state;
    if (s is! HadithReady || s.offset <= 0) return Future.value();
    return _load(s.offset - pageSize);
  }
}
