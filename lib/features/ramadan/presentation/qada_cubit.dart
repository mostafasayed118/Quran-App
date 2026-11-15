import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';
import 'package:quran_yahdi/core/utils/serial_queue.dart';

import '../data/qada_repository.dart';
import '../data/qada_source.dart';
import 'qada_state.dart';

/// The missed-fast list: add a day, remove one, or clear the set.
///
/// Every mutation is optimistic, but the writes are serialized and each one is
/// computed from the **last saved** state, not from the optimistic one:
/// - two overlapping saves cannot finish out of order and leave the older list
///   stored;
/// - a save that fails is not carried into the next write, and the revert goes
///   to the last confirmed list rather than to a pre-mutation snapshot that may
///   be older than a newer committed save.
class QadaCubit extends Cubit<QadaState> {
  /// Creates the cubit over [source].
  QadaCubit({required QadaSource source})
      : _source = source,
        super(const QadaState.loading());

  final QadaSource _source;
  final SerialQueue _writes = SerialQueue();

  /// The list that is actually stored; the base for every queued write.
  List<DateTime> _confirmed = const <DateTime>[];

  /// Monotonic mutation counter: a failing task only repaints when no newer
  /// mutation is waiting behind it.
  int _revision = 0;

  /// Loads the recorded days.
  Future<void> start() async {
    try {
      final dates = await _source.loadMissed();
      _confirmed = dates;
      if (!isClosed) emit(QadaState.ready(dates: dates));
    } on Object catch (error, stackTrace) {
      appLog('qada load failed',
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
  ) {
    final current = state;
    if (current is! QadaReady) return Future<bool>.value(false);
    final optimistic = QadaRepository.normalize(update(current.dates));
    if (_sameList(optimistic, current.dates)) return Future<bool>.value(true);
    emit(QadaState.ready(dates: optimistic));
    final revision = ++_revision;
    return _writes.add(() async {
      final next = QadaRepository.normalize(update(_confirmed));
      if (_sameList(next, _confirmed)) {
        if (!isClosed && revision == _revision) {
          emit(QadaState.ready(dates: _confirmed));
        }
        return true;
      }
      try {
        await _source.saveMissed(next);
        _confirmed = next;
        if (!isClosed && revision == _revision) {
          emit(QadaState.ready(dates: next));
        }
        return true;
      } on Object catch (error, stackTrace) {
        appLog('qada save failed',
            name: 'quran_yahdi/ramadan', error: error, stackTrace: stackTrace);
        if (!isClosed && revision == _revision) {
          emit(QadaState.ready(dates: _confirmed));
        }
        return false;
      }
    });
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
