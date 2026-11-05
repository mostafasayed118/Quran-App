import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/qada_repository.dart';
import '../data/qada_source.dart';
import 'qada_state.dart';

/// The missed-fast list: add a day, remove one, or clear the set.
///
/// Every mutation is optimistic and reverts to the previous state when the
/// write fails, so the counter never claims a day that is not stored.
class QadaCubit extends Cubit<QadaState> {
  /// Creates the cubit over [source].
  QadaCubit({required QadaSource source})
      : _source = source,
        super(const QadaState.loading());

  final QadaSource _source;

  /// Loads the recorded days.
  Future<void> start() async {
    try {
      final dates = await _source.loadMissed();
      if (!isClosed) emit(QadaState.ready(dates: dates));
    } on Object catch (error, stackTrace) {
      dev.log('qada load failed',
          name: 'quran_yahdi/ramadan', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const QadaState.failed());
    }
  }

  /// Adds [date]; a date already in the set is a successful no-op.
  Future<bool> add(DateTime date) => _mutate((dates) => [...dates, date]);

  /// Removes [date]; a date not in the set is a successful no-op.
  Future<bool> remove(DateTime date) => _mutate(
        (dates) => [
          for (final entry in dates)
            if (!_sameDay(entry, date)) entry,
        ],
      );

  /// Removes every recorded day.
  Future<bool> clear() => _mutate((_) => const <DateTime>[]);

  Future<bool> _mutate(
    List<DateTime> Function(List<DateTime> dates) update,
  ) async {
    final current = state;
    if (current is! QadaReady) return false;
    final next = QadaRepository.normalize(update(current.dates));
    if (_sameList(next, current.dates)) return true;
    emit(QadaState.ready(dates: next));
    try {
      await _source.saveMissed(next);
      return true;
    } on Object catch (error, stackTrace) {
      dev.log('qada save failed',
          name: 'quran_yahdi/ramadan', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(current);
      return false;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _sameList(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
