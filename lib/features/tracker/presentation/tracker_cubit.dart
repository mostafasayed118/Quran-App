import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/prayer_log_repository.dart';
import 'tracker_state.dart';

class TrackerCubit extends Cubit<TrackerState> {
  TrackerCubit({required PrayerLogRepository repo})
      : _repo = repo,
        super(const TrackerState.loading()) {
    unawaited(_hydrate());
  }

  /// Used by red-first tests to await the initial load deterministically.
  final Completer<void> _loaded = Completer<void>();

  Future<void> get loaded => _loaded.future;

  final PrayerLogRepository _repo;

  Future<void> _hydrate() async {
    try {
      await reload();
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  Future<void> reload() async {
    try {
      final now = DateTime.now();
      final today = await _repo.dayView(now);
      final marked = await _repo.markedDaysRange(now, 400);
      final last7 = <bool>[
        for (var i = 0; i < 7; i++)
          marked.any((d) => _sameDay(d, now.subtract(Duration(days: i)))),
      ];
      final streak = _computeStreak(marked, now);
      if (isClosed) return;
      emit(TrackerState.ready(
        today: today,
        streakDays: streak,
        last7: last7,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('tracker load failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const TrackerState.failed());
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Consecutive marked days ending today — or yesterday, when today is
  /// still unmarked (so the streak survives the morning). PM ruling, W5.
  int _computeStreak(List<DateTime> marked, DateTime now) {
    final keys = <String>{
      for (final day in marked) _key(day),
    };
    var cursor = DateTime(now.year, now.month, now.day);
    if (!keys.contains(_key(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (keys.contains(_key(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _key(DateTime day) => '${day.year}-${day.month}-${day.day}';

  Future<void> toggle(PrayerSlot slot) async {
    try {
      await _repo.togglePrayer(DateTime.now(), slot);
    } on Object catch (error, stackTrace) {
      dev.log('tracker toggle failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      return;
    }
    await reload();
  }
}
