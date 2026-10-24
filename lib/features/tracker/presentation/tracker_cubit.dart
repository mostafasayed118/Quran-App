import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/date_only.dart';
import '../data/khatma_progress.dart';
import '../data/khatma_repository.dart';
import '../data/prayer_log_repository.dart';
import 'tracker_state.dart';

/// The tracker screen: today's prayer marks, the streak and the khatma card.
class TrackerCubit extends Cubit<TrackerState> {
  static const int _streakLookbackDays = 400;
  static const int _last7DayCount = 7;
  static const int _streakGraceDays = 1;

  /// Creates the cubit and hydrates it.
  ///
  /// [khatma] is optional — without it the khatma card is hidden. The
  /// hydration is fire-and-forget; await [loaded] to wait for it.
  TrackerCubit({
    required PrayerLogRepository repo,
    KhatmaRepository? khatma,
    DateTime Function()? clock,
  })  : _repo = repo,
        _khatma = khatma,
        _clock = clock ?? DateTime.now,
        super(const TrackerState.loading()) {
    unawaited(_hydrate());
  }

  /// Used by red-first tests to await the initial load deterministically.
  final Completer<void> _loaded = Completer<void>();

  /// Completes when the first load has settled (success or failure).
  Future<void> get loaded => _loaded.future;

  final PrayerLogRepository _repo;
  final KhatmaRepository? _khatma;
  final DateTime Function() _clock;

  int _reloadSeq = 0;
  final Set<PrayerSlot> _pendingToggles = <PrayerSlot>{};

  Future<void> _hydrate() async {
    try {
      await reload();
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// Loads today's prayer marks, the streak, the last 7 days and the khatma
  /// card, then emits the ready state.
  ///
  /// A failure emits the failed state (the error is logged, never raised as
  /// an unhandled async error).
  Future<void> reload() async {
    final seq = ++_reloadSeq;
    try {
      final now = _clock();
      final today = await _repo.dayView(now);
      final marked = await _repo.markedDaysRange(now, _streakLookbackDays);
      final last7 = <bool>[
        for (var i = 0; i < _last7DayCount; i++)
          marked.any((d) => _sameDay(d, _daysBefore(now, i))),
      ];
      final streak = _computeStreak(marked, now);
      final khatma = await _loadKhatma();
      if (isClosed || seq != _reloadSeq) return;
      emit(TrackerState.ready(
        today: today,
        streakDays: streak,
        last7: last7,
        khatmaAvailable: khatma.available,
        khatma: khatma.progress,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('tracker load failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      if (isClosed || seq != _reloadSeq) return;
      emit(const TrackerState.failed());
    }
  }

  /// Best-effort: a khatma read failure hides the card instead of failing
  /// the whole tracker screen (the prayer log is the load-bearing surface).
  Future<({bool available, KhatmaProgress? progress})> _loadKhatma() async {
    final repo = _khatma;
    if (repo == null) return (available: false, progress: null);
    try {
      final plan = await repo.currentPlan();
      if (plan == null) return (available: true, progress: null);
      final anchor = await repo.anchorFor(plan.ayahId);
      if (anchor == null) return (available: true, progress: null);
      return (
        available: true,
        progress: KhatmaProgress(
          pointerAyahId: plan.ayahId,
          pointerPage: anchor.page,
          targetPages: plan.targetPages,
          readerSurahId: anchor.surahId,
          readerAyahNumber: anchor.numberInSurah,
        ),
      );
    } on Object catch (error, stackTrace) {
      dev.log('khatma load failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      return (available: false, progress: null);
    }
  }

  /// Starts (or restarts) the plan at [targetPages] and reloads the card.
  Future<void> startKhatma(int targetPages) async {
    final repo = _khatma;
    if (repo == null) return;
    try {
      await repo.startPlan(targetPages);
    } on Object catch (error, stackTrace) {
      dev.log('khatma start failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      _markActionFailed();
      return;
    }
    await reload();
  }

  /// Manual daily advance: moves the pointer one day's portion ahead (or
  /// completes the plan when that portion reaches the last page).
  Future<void> finishWirdToday() async {
    final repo = _khatma;
    if (repo == null) return;
    try {
      final plan = await repo.currentPlan();
      if (plan == null) return;
      final anchor = await repo.anchorFor(plan.ayahId);
      if (anchor == null) return;
      final nextPage =
          anchor.page + KhatmaProgress.dailyPagesFor(plan.targetPages);
      if (nextPage >= KhatmaProgress.totalPages) {
        await repo.complete();
      } else {
        final first = await repo.firstAyahIdOfPage(nextPage);
        if (first == null) return;
        await repo.advanceTo(first);
      }
    } on Object catch (error, stackTrace) {
      dev.log('khatma advance failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      _markActionFailed();
      return;
    }
    await reload();
  }

  /// Deletes the plan (back to the setup card).
  Future<void> resetKhatma() async {
    final repo = _khatma;
    if (repo == null) return;
    try {
      await repo.reset();
    } on Object catch (error, stackTrace) {
      dev.log('khatma reset failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      _markActionFailed();
      return;
    }
    await reload();
  }

  /// Flags a failed user action so the screen can show localized feedback.
  void _markActionFailed() {
    if (isClosed) return;
    final current = state;
    if (current is TrackerReady) {
      emit(current.copyWith(actionFailed: true));
    }
  }

  /// Clears the failure flag after the screen has shown its feedback.
  void acknowledgeActionFailure() {
    if (isClosed) return;
    final current = state;
    if (current is TrackerReady && current.actionFailed) {
      emit(current.copyWith(actionFailed: false));
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _daysBefore(DateTime day, int n) =>
      DateTime(day.year, day.month, day.day - n);

  /// Consecutive marked days ending today — or yesterday, when today is
  /// still unmarked (so the streak survives the morning). PM ruling, W5.
  int _computeStreak(List<DateTime> marked, DateTime now) {
    final keys = <String>{
      for (final day in marked) _key(day),
    };
    var cursor = DateTime(now.year, now.month, now.day);
    if (!keys.contains(_key(cursor))) {
      cursor = _daysBefore(cursor, _streakGraceDays);
    }
    var streak = 0;
    while (keys.contains(_key(cursor))) {
      streak += 1;
      cursor = _daysBefore(cursor, 1);
    }
    return streak;
  }

  String _key(DateTime day) => dayKey(day);

  /// Marks or unmarks one prayer slot for today and reloads the screen.
  ///
  /// A second tap on the same slot while its write is in flight is ignored;
  /// taps on different slots still proceed independently.
  Future<void> toggle(PrayerSlot slot) async {
    if (isClosed || !_pendingToggles.add(slot)) return;
    try {
      await _repo.togglePrayer(_clock(), slot);
    } on Object catch (error, stackTrace) {
      dev.log('tracker toggle failed',
          name: 'quran_yahdi/tracker', error: error, stackTrace: stackTrace);
      _markActionFailed();
      return;
    } finally {
      _pendingToggles.remove(slot);
    }
    await reload();
  }
}
