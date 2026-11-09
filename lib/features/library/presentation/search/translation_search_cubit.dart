import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_search.dart';
import '../../data/translation_search_source.dart';
import 'translation_search_state.dart';

/// Resolves a surah id to its Arabic name; null when unknown.
typedef SurahNameResolver = Future<String?> Function(int surahId);

/// Searches every installed translation pack locally.
///
/// The packs are loaded once at [start]; a query is a normalized substring
/// scan over the in-memory indexes, so no network or DB write is involved.
class TranslationSearchCubit extends Cubit<TranslationSearchState> {
  /// Creates the cubit with the injected read seam and name resolver.
  TranslationSearchCubit({
    required TranslationSearchSource source,
    required SurahNameResolver surahName,
    Duration debounce = const Duration(milliseconds: 300),
  })  : _source = source,
        _surahName = surahName,
        _debounceDuration = debounce,
        super(const TranslationSearchState.loading());

  final TranslationSearchSource _source;
  final SurahNameResolver _surahName;
  final Duration _debounceDuration;
  final List<_Entry> _entries = <_Entry>[];

  /// Surah names are static content; resolve each id at most once per cubit
  /// lifetime instead of on every keystroke.
  final Map<int, String> _surahNames = <int, String>{};

  Timer? _timer;
  bool _started = false;
  int _generation = 0;

  /// The most hits one query renders; [TranslationSearchReady.total] still
  /// counts every match.
  static const int maxHits = 100;

  /// Loads the installed translation indexes.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final ids = await _source.installedTranslationIds();
      if (ids.isEmpty) {
        if (!isClosed) {
          emit(const TranslationSearchState.ready(hasPacks: false));
        }
        return;
      }
      _entries.clear();
      for (final id in ids) {
        final index = await _source.translationIndex(id);
        for (final entry in index.entries) {
          final text = entry.value;
          _entries.add(_Entry(
            surah: entry.key ~/ 1000,
            ayah: entry.key % 1000,
            text: text,
            prepared: prepareQuery(text),
          ));
        }
      }
      if (!isClosed) {
        emit(const TranslationSearchState.ready(hasPacks: true));
      }
    } on Object catch (error, stackTrace) {
      dev.log('translation search load failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const TranslationSearchState.failed());
    }
  }

  /// Debounces [value] and searches the preloaded indexes.
  void setQuery(String value) {
    _timer?.cancel();
    final current = state;
    if (isClosed || current is! TranslationSearchReady || !current.hasPacks) {
      return;
    }
    final generation = ++_generation;
    final query = value.trim();
    if (query.isEmpty) {
      emit(const TranslationSearchState.ready(hasPacks: true));
      return;
    }
    _timer = Timer(
      _debounceDuration,
      () => unawaited(_run(query, generation)),
    );
  }

  Future<void> _run(String query, int generation) async {
    final prepared = prepareQuery(query);
    final matches = <_Entry>[];
    var total = 0;
    for (final entry in _entries) {
      if (entry.prepared.contains(prepared)) {
        total += 1;
        if (matches.length < maxHits) matches.add(entry);
      }
    }
    final names = _surahNames;
    final missing = <int>{for (final match in matches) match.surah}
        .difference(names.keys.toSet());
    if (missing.isNotEmpty) {
      final resolved = await Future.wait([
        for (final id in missing)
          () async {
            try {
              return (id, await _surahName(id) ?? '');
            } on Object catch (error, stackTrace) {
              dev.log(
                'surah name lookup failed',
                name: 'quran_yahdi/library',
                error: error,
                stackTrace: stackTrace,
              );
              return (id, '');
            }
          }(),
      ]);
      for (final (id, name) in resolved) {
        names[id] = name;
      }
    }
    if (isClosed || generation != _generation) return;
    emit(TranslationSearchState.ready(
      hasPacks: true,
      query: query,
      total: total,
      hits: [
        for (final match in matches)
          TranslationHit(
            surahId: match.surah,
            ayah: match.ayah,
            text: match.text,
            surahName: names[match.surah] ?? '',
          ),
      ],
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class _Entry {
  const _Entry({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.prepared,
  });

  final int surah;
  final int ayah;
  final String text;
  final String prepared;
}
