import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';

import 'prayer_config_state.dart';

/// The prayer settings screen: calculation method and Asr madhab.
///
/// The constructor is side-effect free; the route scope calls [start] once.
/// Every setter only builds on a confirmed [PrayerConfigReady] and keeps the
/// last saved configuration if the write fails.
class PrayerConfigCubit extends Cubit<PrayerConfigState> {
  /// Creates the cubit over [source].
  PrayerConfigCubit({required PrayerConfigSource source})
      : _source = source,
        super(const PrayerConfigState.loading());

  final PrayerConfigSource _source;

  /// Loads the persisted configuration.
  Future<void> start() async {
    try {
      final config = await _source.load();
      if (!isClosed) emit(PrayerConfigState.ready(config));
    } on Object catch (error, stackTrace) {
      dev.log('prayer config load failed',
          name: 'quran_yahdi/prayer', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const PrayerConfigState.failed());
    }
  }

  /// Selects [method] and persists it.
  Future<void> setMethod(PrayerCalculationMethod method) {
    final current = state;
    if (current is! PrayerConfigReady || current.config.method == method) {
      return Future<void>.value();
    }
    return _save(current.config.copyWith(method: method));
  }

  /// Selects [madhab] and persists it.
  Future<void> setMadhab(PrayerMadhab madhab) {
    final current = state;
    if (current is! PrayerConfigReady || current.config.madhab == madhab) {
      return Future<void>.value();
    }
    return _save(current.config.copyWith(madhab: madhab));
  }

  Future<void> _save(PrayerConfig next) async {
    try {
      await _source.save(next);
      if (!isClosed) emit(PrayerConfigState.ready(next));
    } on Object catch (error, stackTrace) {
      // Keep the last confirmed state; the screen keeps showing it.
      dev.log('prayer config save failed',
          name: 'quran_yahdi/prayer', error: error, stackTrace: stackTrace);
    }
  }
}
