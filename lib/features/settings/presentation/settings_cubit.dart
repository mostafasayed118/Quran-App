import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';

import 'settings_state.dart';

/// W7b settings surface: the prayer, azkar and wird reminder toggles + times.
/// Persists through the reminder settings ports and re-plans through the
/// shared guarded scheduler path after every change; when enabling azkar or
/// wird, it also drives the OS permission flow.
///
/// A mutation only ever builds on a confirmed [SettingsReady]: issued while
/// the load is still running or after it failed, it is dropped instead of
/// emitting a ready state with values that were never read from storage.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates the cubit; the constructor is side-effect free. The route scope
  /// calls [start] once to run the first load, which moves the state from
  /// loading to ready/failed.
  ///
  /// [prayerSettings] is optional so existing constructions (and fakes) that
  /// only know [ReminderSettingsPort] keep compiling; when it is absent the
  /// prayer reminder is reported as enabled (its historical behaviour).
  SettingsCubit({
    required ReminderSettingsPort settings,
    PrayerReminderSettingsPort? prayerSettings,
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  })  : _settings = settings,
        _prayerSettings = prayerSettings,
        _city = city,
        _prayer = prayer,
        _scheduler = scheduler,
        super(const SettingsState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() => load();

  final ReminderSettingsPort _settings;
  final PrayerReminderSettingsPort? _prayerSettings;
  final CitySource _city;
  final PrayerTimesPort _prayer;
  final ReminderSchedulerPort _scheduler;

  Future<void> _mutations = Future<void>.value();

  /// Runs [op] after every mutation already queued, so overlapping setters
  /// cannot recompose the ready state from a stale snapshot.
  Future<void> _serialized(Future<void> Function() op) {
    final result = _mutations.then<void>((_) => op());
    _mutations = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Loads the stored reminder flags and times and emits them.
  ///
  /// A failure emits the failed state (the error is logged, never raised as
  /// an unhandled async error).
  Future<void> load() async {
    try {
      final prayerEnabled = await _prayerSettings?.prayerEnabled() ?? true;
      final enabled = await _settings.azkarEnabled();
      final time = await _settings.azkarTimeHm() ?? defaultAzkarTimeHm;
      final wirdEnabled = await _settings.wirdEnabled();
      final wirdTime = await _settings.wirdTimeHm() ?? defaultWirdTimeHm;
      if (isClosed) return;
      emit(SettingsState.ready(
        prayerEnabled: prayerEnabled,
        azkarEnabled: enabled,
        azkarTimeHm: time,
        wirdEnabled: wirdEnabled,
        wirdTimeHm: wirdTime,
        azkarPermissionDenied: false,
        wirdPermissionDenied: false,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('settings load failed',
          name: 'quran_yahdi/settings', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const SettingsState.failed());
    }
  }

  /// Enables or disables the prayer reminder and re-plans the schedule.
  ///
  /// The prayer reminder needs no extra OS permission flow. A failed write is
  /// logged and the last confirmed state is kept.
  Future<void> setPrayerEnabled(bool enabled) {
    return _serialized(() async {
      var current = _readyState();
      if (current == null) return;
      try {
        await _prayerSettings?.setPrayerEnabled(enabled);
        await _reschedule();
        current = _readyState();
        if (current == null) return;
        emit(current.copyWith(prayerEnabled: enabled));
      } on Object catch (error, stackTrace) {
        _logMutationFailure('setPrayerEnabled', error, stackTrace);
      }
    });
  }

  /// Enables or disables the azkar reminder and re-plans the schedule.
  ///
  /// Enabling asks for the OS notification permission; a refusal is reported
  /// through [SettingsReady.azkarPermissionDenied], not as an error state. A
  /// failed write is logged and the last confirmed state is kept.
  Future<void> setAzkarEnabled(bool enabled) {
    return _serialized(() async {
      var current = _readyState();
      if (current == null) return;
      try {
        await _settings.setAzkarEnabled(enabled);
        var denied = false;
        if (enabled) {
          denied = !(await _scheduler.ensurePermissions());
        }
        await _reschedule();
        current = _readyState();
        if (current == null) return;
        emit(current.copyWith(
          azkarEnabled: enabled,
          azkarPermissionDenied: denied,
        ));
      } on Object catch (error, stackTrace) {
        _logMutationFailure('setAzkarEnabled', error, stackTrace);
      }
    });
  }

  /// Stores the azkar reminder time [hm] ('HH:mm') and re-plans.
  ///
  /// A failed write is logged and the last confirmed state is kept.
  Future<void> setTime(String hm) {
    return _serialized(() async {
      var current = _readyState();
      if (current == null) return;
      try {
        await _settings.setAzkarTime(hm);
        await _reschedule();
        current = _readyState();
        if (current == null) return;
        emit(current.copyWith(azkarTimeHm: hm));
      } on Object catch (error, stackTrace) {
        _logMutationFailure('setTime', error, stackTrace);
      }
    });
  }

  /// Enables or disables the wird reminder and re-plans the schedule.
  ///
  /// Enabling asks for the OS notification permission; a refusal is reported
  /// through [SettingsReady.wirdPermissionDenied], not as an error state. A
  /// failed write is logged and the last confirmed state is kept.
  Future<void> toggleWird(bool enabled) {
    return _serialized(() async {
      var current = _readyState();
      if (current == null) return;
      try {
        await _settings.setWirdEnabled(enabled);
        var denied = false;
        if (enabled) {
          denied = !(await _scheduler.ensurePermissions());
        }
        await _reschedule();
        current = _readyState();
        if (current == null) return;
        emit(current.copyWith(
          wirdEnabled: enabled,
          wirdPermissionDenied: denied,
        ));
      } on Object catch (error, stackTrace) {
        _logMutationFailure('toggleWird', error, stackTrace);
      }
    });
  }

  /// Stores the wird reminder time [hm] ('HH:mm') and re-plans.
  ///
  /// A failed write is logged and the last confirmed state is kept.
  Future<void> changeWirdTime(String hm) {
    return _serialized(() async {
      var current = _readyState();
      if (current == null) return;
      try {
        await _settings.setWirdTime(hm);
        await _reschedule();
        current = _readyState();
        if (current == null) return;
        emit(current.copyWith(wirdTimeHm: hm));
      } on Object catch (error, stackTrace) {
        _logMutationFailure('changeWirdTime', error, stackTrace);
      }
    });
  }

  /// Logs a failed mutation; the UI keeps the last confirmed state
  /// (user-facing failure feedback is a separate owner decision).
  void _logMutationFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    dev.log(
      'settings $operation failed',
      name: 'quran_yahdi/settings',
      error: error.runtimeType,
      stackTrace: stackTrace,
    );
  }

  Future<void> _reschedule() => _settings.reschedule(
        city: _city,
        prayer: _prayer,
        scheduler: _scheduler,
      );

  /// The state a mutation may build on, or null when there is nothing
  /// confirmed to build on: the cubit is closed, still loading, or the load
  /// failed. Reading it again after the awaits also covers a load that lands
  /// (and fails) while a mutation is in flight.
  SettingsReady? _readyState() {
    if (isClosed) return null;
    final current = state;
    return current is SettingsReady ? current : null;
  }
}
