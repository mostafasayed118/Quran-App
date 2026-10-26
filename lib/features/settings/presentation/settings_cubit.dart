import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';

import 'settings_state.dart';

/// W7b settings surface: the azkar and wird reminder toggles + times. Persists
/// through the reminder settings port and re-plans through the shared guarded
/// scheduler path after every change; when enabling, it also drives the OS
/// permission flow.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates the cubit; the constructor is side-effect free. The route scope
  /// calls [start] once to run the first load, which moves the state from
  /// loading to ready/failed.
  SettingsCubit({
    required ReminderSettingsPort settings,
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  })  : _settings = settings,
        _city = city,
        _prayer = prayer,
        _scheduler = scheduler,
        super(const SettingsState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() => load();

  final ReminderSettingsPort _settings;
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
      final enabled = await _settings.azkarEnabled();
      final time = await _settings.azkarTimeHm() ?? defaultAzkarTimeHm;
      final wirdEnabled = await _settings.wirdEnabled();
      final wirdTime = await _settings.wirdTimeHm() ?? defaultWirdTimeHm;
      if (isClosed) return;
      emit(SettingsState.ready(
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

  /// Enables or disables the azkar reminder and re-plans the schedule.
  ///
  /// Enabling asks for the OS notification permission; a refusal is reported
  /// through [SettingsReady.azkarPermissionDenied], not as an error state. A
  /// failed write is logged and the last confirmed state is kept.
  Future<void> setAzkarEnabled(bool enabled) {
    return _serialized(() async {
      try {
        await _settings.setAzkarEnabled(enabled);
        var denied = false;
        if (enabled) {
          denied = !(await _scheduler.ensurePermissions());
        }
        await _reschedule();
        if (isClosed) return;
        emit(SettingsState.ready(
          azkarEnabled: enabled,
          azkarTimeHm: _timeOf(state),
          wirdEnabled: _wirdEnabledOf(state),
          wirdTimeHm: _wirdTimeOf(state),
          azkarPermissionDenied: denied,
          wirdPermissionDenied: _wirdDeniedOf(state),
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
      try {
        await _settings.setAzkarTime(hm);
        await _reschedule();
        if (isClosed) return;
        emit(SettingsState.ready(
          azkarEnabled: _enabledOf(state),
          azkarTimeHm: hm,
          wirdEnabled: _wirdEnabledOf(state),
          wirdTimeHm: _wirdTimeOf(state),
          azkarPermissionDenied: _azkarDeniedOf(state),
          wirdPermissionDenied: _wirdDeniedOf(state),
        ));
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
      try {
        await _settings.setWirdEnabled(enabled);
        var denied = false;
        if (enabled) {
          denied = !(await _scheduler.ensurePermissions());
        }
        await _reschedule();
        if (isClosed) return;
        emit(SettingsState.ready(
          azkarEnabled: _enabledOf(state),
          azkarTimeHm: _timeOf(state),
          wirdEnabled: enabled,
          wirdTimeHm: _wirdTimeOf(state),
          azkarPermissionDenied: _azkarDeniedOf(state),
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
      try {
        await _settings.setWirdTime(hm);
        await _reschedule();
        if (isClosed) return;
        emit(SettingsState.ready(
          azkarEnabled: _enabledOf(state),
          azkarTimeHm: _timeOf(state),
          wirdEnabled: _wirdEnabledOf(state),
          wirdTimeHm: hm,
          azkarPermissionDenied: _azkarDeniedOf(state),
          wirdPermissionDenied: _wirdDeniedOf(state),
        ));
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

  String _timeOf(SettingsState state) => switch (state) {
        SettingsReady(:final azkarTimeHm) => azkarTimeHm,
        SettingsLoading() => defaultAzkarTimeHm,
        SettingsFailed() => defaultAzkarTimeHm,
      };

  bool _enabledOf(SettingsState state) => switch (state) {
        SettingsReady(:final azkarEnabled) => azkarEnabled,
        SettingsLoading() => false,
        SettingsFailed() => false,
      };

  bool _azkarDeniedOf(SettingsState state) => switch (state) {
        SettingsReady(:final azkarPermissionDenied) => azkarPermissionDenied,
        SettingsLoading() => false,
        SettingsFailed() => false,
      };

  bool _wirdDeniedOf(SettingsState state) => switch (state) {
        SettingsReady(:final wirdPermissionDenied) => wirdPermissionDenied,
        SettingsLoading() => false,
        SettingsFailed() => false,
      };

  bool _wirdEnabledOf(SettingsState state) => switch (state) {
        SettingsReady(:final wirdEnabled) => wirdEnabled,
        SettingsLoading() => false,
        SettingsFailed() => false,
      };

  String _wirdTimeOf(SettingsState state) => switch (state) {
        SettingsReady(:final wirdTimeHm) => wirdTimeHm,
        SettingsLoading() => defaultWirdTimeHm,
        SettingsFailed() => defaultWirdTimeHm,
      };
}
