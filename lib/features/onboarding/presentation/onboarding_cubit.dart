import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';

import '../../../core/domain/onboarding_status.dart';
import 'onboarding_state.dart';

/// Drives the setup flow: the city step, the reminder step and the flag.
///
/// Every step is optional. The flow never gates the app — finishing or
/// skipping only stops Home from advertising it.
class OnboardingCubit extends Cubit<OnboardingState> {
  /// Creates the cubit; the constructor is side-effect free and does no work
  /// — [start] performs the first read.
  OnboardingCubit({
    required CitySource city,
    required OnboardingStatusSource status,
    required ReminderSchedulerPort reminders,
  })  : _city = city,
        _status = status,
        _reminders = reminders,
        super(const OnboardingState.loading());

  final CitySource _city;
  final OnboardingStatusSource _status;
  final ReminderSchedulerPort _reminders;

  /// Reads the flag and the current step status.
  Future<void> start() async {
    final completed = await _readCompleted();
    if (isClosed) return;
    if (completed) {
      emit(const OnboardingState.ready(completed: true));
      return;
    }
    final city = await _readCity();
    if (isClosed) return;
    emit(OnboardingState.ready(
      citySelected: city != null,
      cityName: city?.nameAr,
    ));
  }

  /// Re-reads the city after the picker pops (the user may have changed it).
  Future<void> refreshCity() async {
    final state = this.state;
    if (state is! OnboardingReady || state.completed) return;
    final city = await _readCity();
    if (isClosed) return;
    emit(state.copyWith(
      citySelected: city != null,
      cityName: city?.nameAr,
    ));
  }

  /// Asks the OS for the notification permission through the reminder seam.
  Future<void> requestReminders() async {
    final state = this.state;
    if (state is! OnboardingReady || state.completed) return;
    var granted = false;
    try {
      granted = await _reminders.ensurePermissions();
    } on Object catch (error, stackTrace) {
      appLog('onboarding permission request failed',
          name: 'quran_yahdi/onboarding', error: error, stackTrace: stackTrace);
    }
    if (isClosed) return;
    final current = this.state;
    if (current is! OnboardingReady) return;
    emit(current.copyWith(remindersGranted: granted));
  }

  /// Stores the flag (finish or skip) and emits the completed state.
  Future<void> finish() async {
    final state = this.state;
    if (state is OnboardingReady && state.completed) return;
    try {
      await _status.markCompleted();
    } on Object catch (error, stackTrace) {
      appLog('onboarding flag write failed',
          name: 'quran_yahdi/onboarding', error: error, stackTrace: stackTrace);
    }
    if (isClosed) return;
    final current = this.state;
    emit(current is OnboardingReady
        ? current.copyWith(completed: true)
        : const OnboardingState.ready(completed: true));
  }

  Future<bool> _readCompleted() async {
    try {
      return await _status.isCompleted();
    } on Object catch (error, stackTrace) {
      appLog('onboarding flag read failed',
          name: 'quran_yahdi/onboarding', error: error, stackTrace: stackTrace);
      // Never nag a user we cannot read: treat the flow as done.
      return true;
    }
  }

  Future<City?> _readCity() async {
    try {
      return await _city.selectedCity();
    } on Object catch (error, stackTrace) {
      appLog('onboarding city read failed',
          name: 'quran_yahdi/onboarding', error: error, stackTrace: stackTrace);
      return null;
    }
  }
}
