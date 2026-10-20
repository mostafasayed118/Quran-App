import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';

import 'prayer_times_state.dart';

/// The prayer times screen: today's prayers, the next one and the countdown.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  /// Creates the cubit and starts the first load.
  ///
  /// [clock] is the time seam (defaults to [DateTime.now]); [settings] and
  /// [scheduler] are optional — without them no reminder is (re)planned.
  PrayerTimesCubit({
    required PrayerTimesPort prayer,
    required CitySource city,
    ReminderSettingsPort? settings,
    ReminderSchedulerPort? scheduler,
    DateTime Function()? clock,
  })  : _prayer = prayer,
        _city = city,
        _settings = settings,
        _scheduler = scheduler,
        _clock = clock ?? DateTime.now,
        super(const PrayerTimesState.loading()) {
    unawaited(reload());
  }

  final PrayerTimesPort _prayer;
  final CitySource _city;
  final ReminderSettingsPort? _settings;
  final ReminderSchedulerPort? _scheduler;
  final DateTime Function() _clock;

  DateTime? _loadedDay;

  /// Loads the selected city, today's prayers and the countdown, then emits
  /// the ready state.
  ///
  /// With no selected city the ready state carries no entries. A failure
  /// emits the failed state (the error is logged, never raised as an
  /// unhandled async error).
  Future<void> reload() async {
    try {
      final selected = await _city.selectedCity();
      if (isClosed) return;
      if (selected == null) {
        emit(const PrayerTimesState.ready());
        return;
      }
      final now = _clock();
      final next = _prayer.nextPrayer(selected.coordinates, now);
      final entries = <PrayerEntry>[
        for (final choice in _prayer.today(selected.coordinates, now))
          PrayerEntry(
            name: choice.name,
            time: choice.time,
            // Same-occurrence match: after Isha the service returns tomorrow's
            // Fajr — it must not flag today's already-passed Fajr row.
            isNext: choice.name == next.name &&
                choice.time.isAtSameMomentAs(next.time),
          ),
      ];
      final nextEntry = entries
          .where((e) => e.isNext)
          .fold<PrayerEntry?>(null, (best, e) => best ?? e);
      final remaining = nextEntry?.time.difference(now);
      if (isClosed) return;
      _loadedDay = DateTime(now.year, now.month, now.day);
      emit(PrayerTimesState.ready(
        city: selected,
        entries: entries,
        remaining:
            remaining != null && remaining > Duration.zero ? remaining : null,
      ));
      _scheduleReminders();
    } on Object catch (error, stackTrace) {
      dev.log('prayer times load failed',
          name: 'quran_yahdi/prayer_times',
          error: error,
          stackTrace: stackTrace);
      if (isClosed) return;
      emit(const PrayerTimesState.failed());
    }
  }

  /// Recomputes the countdown while the screen is open (the screen owns the
  /// 1 s ticker). Reloads when the flagged prayer passes or the day rolls
  /// over so the highlight never stays on a passed row.
  void refreshCountdown() {
    if (isClosed) return;
    final state = this.state;
    if (state is! PrayerTimesReady || state.city == null) return;
    final now = _clock();
    final loaded = _loadedDay;
    if (loaded == null ||
        now.year != loaded.year ||
        now.month != loaded.month ||
        now.day != loaded.day) {
      unawaited(reload());
      return;
    }
    PrayerEntry? nextEntry;
    for (final entry in state.entries) {
      if (entry.isNext) {
        nextEntry = entry;
        break;
      }
    }
    if (nextEntry == null) return;
    final remaining = nextEntry.time.difference(now);
    if (remaining <= Duration.zero) {
      unawaited(reload());
      return;
    }
    final current = state.remaining;
    if (current == null || current.inMinutes != remaining.inMinutes) {
      emit(state.copyWith(remaining: remaining));
    }
  }

  /// W7b: reminders are (re)computed after every successful load (startup +
  /// city/selection change). Fire-and-forget; the shared helper never throws.
  void _scheduleReminders() {
    final settings = _settings;
    final scheduler = _scheduler;
    if (settings == null || scheduler == null) return;
    unawaited(settings.reschedule(
      city: _city,
      prayer: _prayer,
      scheduler: scheduler,
    ));
  }

  /// Stores [city] as the selected city and reloads the prayers.
  Future<void> select(City city) async {
    await _city.select(city);
    await reload();
  }
}
