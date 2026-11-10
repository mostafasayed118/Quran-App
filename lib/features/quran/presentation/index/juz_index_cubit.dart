import 'dart:async';
import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/juz_index_source.dart';
import '../../domain/juz_summary.dart';
import 'juz_index_state.dart';

/// Loads the derived juz index for the surah-index screen.
class JuzIndexCubit extends Cubit<JuzIndexState> {
  /// Creates the cubit; the route scope calls [start] once.
  JuzIndexCubit({required JuzIndexSource source})
      : _source = source,
        super(const JuzIndexState.loading());

  final JuzIndexSource _source;
  StreamSubscription<List<JuzSummary>>? _sub;

  /// Starts the live read.
  Future<void> start() async {
    try {
      _sub = _source.watchJuz().listen(
        (juz) {
          if (!isClosed) emit(JuzIndexState.ready(juz));
        },
        onError: (Object error, StackTrace stackTrace) {
          appLog('juz index stream failed',
              name: 'quran_yahdi/quran', error: error, stackTrace: stackTrace);
          if (!isClosed) emit(const JuzIndexState.failed());
        },
      );
    } on Object catch (error, stackTrace) {
      appLog('juz index load failed',
          name: 'quran_yahdi/quran', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const JuzIndexState.failed());
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
