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
  })  : _prayer = prayer,
        _city = city,
        _scheduler = scheduler,
        _reminderSettings = reminderSettings,
        super(const PrayerTimesState.loading()) {
    unawaited(reload());
  }

  final PrayerTimeService _prayer;
  final CityRepository _city;
  final ReminderScheduler? _scheduler;
  final ReminderSettings? _reminderSettings;

  Future<void> reload() async {
    final selected = await _city.selectedCity();
    if (isClosed) return;
    if (selected == null) {
      emit(const PrayerTimesState.ready());
      return;
    }
    final now = DateTime.now();
    final next = _prayer.nextPrayer(selected.coordinates, now);
    final entries = <PrayerEntry>[
      for (final choice in _prayer.today(selected.coordinates, now))
        PrayerEntry(
          name: choice.name,
          time: choice.time,
          isNext: choice.name == next.name,
        ),
    ];
    final nextEntry = entries
        .where((e) => e.isNext)
        .fold<PrayerEntry?>(null, (best, e) => best ?? e);
    final remaining = nextEntry?.time.difference(now);
    if (isClosed) return;
    emit(PrayerTimesState.ready(
      city: selected,
      entries: entries,
      remaining:
          remaining != null && remaining > Duration.zero ? remaining : null,
    ));
    _scheduleReminders();
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
