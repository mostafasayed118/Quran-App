import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../data/dua_repository.dart';
import '../data/ruqyah_repository.dart';
import '../../quran/data/ayah_repository.dart';
import 'duas_state.dart';

class DuasCubit extends Cubit<DuasState> {
  DuasCubit({
    required DuaRepository duas,
    required RuqyahRepository ruqyah,
    required AyahRepository ayahs,
  })  : _duas = duas,
        _ruqyah = ruqyah,
        _ayahs = ayahs,
        super(const DuasState.loading()) {
    unawaited(showDuas());
  }

  final DuaRepository _duas;
  final RuqyahRepository _ruqyah;
  final AyahRepository _ayahs;

  List<DuaEntry>? _allDuas;
  List<RuqyahResolved>? _resolvedRuqyah;

  Future<void> showDuas() async {
    try {
      // Independent reads: run them concurrently (list form keeps the first
      // error and consumes the other, so nothing leaks as unhandled).
      final results = await Future.wait<Object>([
        _duas.entries(),
        _duas.categories(),
      ]);
      final entries = results[0] as List<DuaEntry>;
      final categories = results[1] as List<String>;
      _allDuas = entries;
      if (isClosed) return;
      emit(DuasState.duas(categories: categories, entries: entries));
    } on Object catch (error, stackTrace) {
      dev.log('duas load failed',
          name: 'quran_yahdi/duas', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const DuasState.failed());
    }
  }

  Future<void> showRuqyah() async {
    final cached = _resolvedRuqyah;
    if (cached != null) {
      if (isClosed) return;
      emit(DuasState.ruqyah(entries: cached));
      return;
    }
    if (isClosed) return;
    emit(const DuasState.loading(tab: DuasTab.ruqyah));
    try {
      final entries = await _ruqyah.entries();
      // Entries are independent; Future.wait preserves list order and the
      // per-entry call sequence (range read, then surah name) is unchanged.
      final resolved = await Future.wait([
        for (final entry in entries) _resolveEntry(entry),
      ]);
      if (isClosed) return;
      _resolvedRuqyah = resolved;
      emit(DuasState.ruqyah(entries: resolved));
    } on Object catch (error, stackTrace) {
      dev.log('ruqyah load failed',
          name: 'quran_yahdi/duas', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const DuasState.failed(tab: DuasTab.ruqyah));
    }
  }

  Future<RuqyahResolved> _resolveEntry(RuqyahEntry entry) async {
    if (entry.isQuran &&
        entry.surahId != null &&
        entry.fromAyah != null &&
        entry.toAyah != null) {
      final ayahs = await _ayahs.ayahsForRange(
        entry.surahId!,
        entry.fromAyah!,
        entry.toAyah!,
      );
      final surah = await _ayahs.surahById(entry.surahId!);
      return RuqyahResolved(
        id: entry.id,
        isQuran: true,
        displayText:
            <String>[for (final ayah in ayahs) ayah.textUthmani].join(' '),
        citation: '${surah?.nameAr ?? ''} '
            '${entry.fromAyah!.toArabicIndic}–${entry.toAyah!.toArabicIndic}',
        reference: entry.reference,
      );
    }
    return RuqyahResolved(
      id: entry.id,
      isQuran: false,
      displayText: entry.text ?? '',
      count: entry.count,
      reference: entry.reference,
    );
  }

  Future<void> selectTab(DuasTab tab) async {
    final isAlreadyDuas = state is DuasInView && tab == DuasTab.duas;
    final isAlreadyRuqyah = state is RuqyahInView && tab == DuasTab.ruqyah;
    if (isAlreadyDuas || isAlreadyRuqyah) return;
    if (tab == DuasTab.duas) {
      await showDuas();
    } else {
      await showRuqyah();
    }
  }

  void selectCategory(String? category) {
    final state = this.state;
    final all = _allDuas;
    if (state is! DuasInView || all == null) return;
    if (isClosed) return;
    emit(DuasState.duas(
      categories: state.categories,
      entries: category == null
          ? all
          : <DuaEntry>[
              for (final entry in all)
                if (entry.categoryAr == category) entry,
            ],
      selectedCategory: category,
    ));
  }
}
