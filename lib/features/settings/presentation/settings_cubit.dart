import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduler.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_scheduling.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

import 'settings_state.dart';

/// W7b settings surface: the azkar and wird reminder toggles + times. Persists
/// through [ReminderSettings] and re-plans through the shared guarded scheduler
/// path after every change; when enabling, it also drives the OS permission
/// flow.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required ReminderSettings settings,
    required CityRepository city,
    required PrayerTimeService prayer,
    required ReminderScheduler scheduler,
  })  : _settings = settings,
        _city = city,
        _prayer = prayer,
        _scheduler = scheduler,
        super(const SettingsState.loading()) {
    unawaited(load());
  }

  final ReminderSettings _settings;
  final CityRepository _city;
  final PrayerTimeService _prayer;
  final ReminderScheduler _scheduler;

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
      ));
    } on Object catch (error, stackTrace) {
      dev.log('settings load failed',
          name: 'quran_yahdi/settings', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const SettingsState.failed());
    }
  }

  Future<void> setAzkarEnabled(bool enabled) async {
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
      permissionDenied: denied,
    ));
  }

  Future<void> setTime(String hm) async {
    await _settings.setAzkarTime(hm);
    await _reschedule();
    if (isClosed) return;
    emit(SettingsState.ready(
      azkarEnabled: _enabledOf(state),
      azkarTimeHm: hm,
      wirdEnabled: _wirdEnabledOf(state),
      wirdTimeHm: _wirdTimeOf(state),
      permissionDenied: _deniedOf(state),
    ));
  }

  Future<void> toggleWird(bool enabled) async {
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
      permissionDenied: denied,
    ));
  }

  Future<void> changeWirdTime(String hm) async {
    await _settings.setWirdTime(hm);
    await _reschedule();
    if (isClosed) return;
    emit(SettingsState.ready(
      azkarEnabled: _enabledOf(state),
      azkarTimeHm: _timeOf(state),
      wirdEnabled: _wirdEnabledOf(state),
      wirdTimeHm: hm,
      permissionDenied: _deniedOf(state),
    ));
  }

  Future<void> _reschedule() => scheduleReminders(
        city: _city,
        prayer: _prayer,
        settings: _settings,
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

  bool _deniedOf(SettingsState state) => switch (state) {
        SettingsReady(:final permissionDenied) => permissionDenied,
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
