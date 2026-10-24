import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../data/dua_repository.dart';
import '../data/ruqyah_repository.dart';
import 'duas_state.dart';

/// The duas/ruqyah screen: the dua list, the category filter and the ruqyah
/// tab (its Quran entries resolve to ayah texts through the ayah port).
class DuasCubit extends Cubit<DuasState> {
  /// Creates the cubit and loads the dua list.
  ///
  /// The load is fire-and-forget: the state moves from loading to
  /// duas/failed on its own.
  DuasCubit({
    required DuaRepository duas,
    required RuqyahRepository ruqyah,
    required AyahLookup ayahs,
  })  : _duas = duas,
        _ruqyah = ruqyah,
        _ayahs = ayahs,
        super(const DuasState.loading()) {
    unawaited(showDuas());
  }

  final DuaRepository _duas;
  final RuqyahRepository _ruqyah;
  final AyahLookup _ayahs;

  List<DuaEntry>? _allDuas;
  List<RuqyahResolved>? _resolvedRuqyah;

  /// Monotonic visible-view token: only the latest tab intent may emit.
  int _viewSeq = 0;

  /// Loads the dua list and its categories and emits them.
  ///
  /// The two reads are independent and run concurrently; the first failure
  /// wins and emits [DuasState.failed] (the other chain is consumed, never
  /// an unhandled async error).
  Future<void> showDuas() async {
    final seq = ++_viewSeq;
    try {
      // Independent reads: run them concurrently (list form keeps the first
      // error and consumes the other, so nothing leaks as unhandled).
      final results = await Future.wait<Object>([
        _duas.entries(),
        _duas.categories(),
      ]);
      final entries = results[0] as List<DuaEntry>;
      final categories = results[1] as List<String>;
      if (isClosed || seq != _viewSeq) return;
      _allDuas = entries;
      emit(DuasState.duas(categories: categories, entries: entries));
    } on Object catch (error, stackTrace) {
      dev.log('duas load failed',
          name: 'quran_yahdi/duas', error: error, stackTrace: stackTrace);
      if (isClosed || seq != _viewSeq) return;
      emit(const DuasState.failed());
    }
  }

  /// Switches to the ruqyah tab and resolves its entries.
  ///
  /// The resolutions are cached: a second visit re-emits the cached rows
  /// instead of re-querying the ayah port.
  Future<void> showRuqyah() async {
    final seq = ++_viewSeq;
    final cached = _resolvedRuqyah;
    if (cached != null) {
      if (isClosed || seq != _viewSeq) return;
      emit(DuasState.ruqyah(entries: cached));
      return;
    }
    if (isClosed || seq != _viewSeq) return;
    emit(const DuasState.loading(tab: DuasTab.ruqyah));
    try {
      final entries = await _ruqyah.entries();
      // Entries are independent; Future.wait preserves list order and the
      // per-entry call sequence (range read, then surah name) is unchanged.
      final resolved = await Future.wait([
        for (final entry in entries) _resolveEntry(entry),
      ]);
      if (isClosed || seq != _viewSeq) return;
      _resolvedRuqyah = resolved;
      emit(DuasState.ruqyah(entries: resolved));
    } on Object catch (error, stackTrace) {
      dev.log('ruqyah load failed',
          name: 'quran_yahdi/duas', error: error, stackTrace: stackTrace);
      if (isClosed || seq != _viewSeq) return;
      emit(const DuasState.failed(tab: DuasTab.ruqyah));
    }
  }

  Future<RuqyahResolved> _resolveEntry(RuqyahEntry entry) async {
    final surahId = entry.surahId;
    final fromAyah = entry.fromAyah;
    final toAyah = entry.toAyah;
    if (entry.isQuran &&
        surahId != null &&
        fromAyah != null &&
        toAyah != null) {
      final ayahs = await _ayahs.ayahRefsForRange(surahId, fromAyah, toAyah);
      final surah = await _ayahs.surahRefById(surahId);
      return RuqyahResolved(
        id: entry.id,
        isQuran: true,
        displayText:
            <String>[for (final ayah in ayahs) ayah.textUthmani].join(' '),
        citation: '${surah?.nameAr ?? ''} '
            '${fromAyah.toArabicIndic}–${toAyah.toArabicIndic}',
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

  /// Switches the visible tab; a no-op when the tab is already shown.
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

  /// Filters the dua list by [category]; null clears the filter.
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
