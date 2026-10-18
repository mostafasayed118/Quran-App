import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notifications/data/reminder_scheduler.dart';
import '../../../notifications/data/reminder_scheduling.dart';
import '../../../notifications/data/reminder_settings.dart';
import '../../data/city_repository.dart';
import '../../data/prayer_time_service.dart';
import 'prayer_times_state.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({
    required PrayerTimeService prayer,
    required CityRepository city,
    ReminderScheduler? scheduler,
    ReminderSettings? reminderSettings,
    DateTime Function()? clock,
  })  : _prayer = prayer,
        _city = city,
        _scheduler = scheduler,
        _reminderSettings = reminderSettings,
        _clock = clock ?? DateTime.now,
        super(const PrayerTimesState.loading()) {
    unawaited(reload());
  }

  final PrayerTimeService _prayer;
  final CityRepository _city;
  final ReminderScheduler? _scheduler;
  final ReminderSettings? _reminderSettings;
  final DateTime Function() _clock;

  DateTime? _loadedDay;

  Future<void> reload() async {
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
    final scheduler = _scheduler;
    final reminderSettings = _reminderSettings;
    if (scheduler == null || reminderSettings == null) return;
    unawaited(scheduleReminders(
      city: _city,
      prayer: _prayer,
      settings: reminderSettings,
      scheduler: scheduler,
    ));
  }

  Future<void> select(City city) async {
    await _city.select(city);
    await reload();
  }
}
