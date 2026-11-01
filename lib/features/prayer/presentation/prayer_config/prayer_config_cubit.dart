import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';

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

  /// Serializes overlapping selections so a quick method + madhab tap cannot
  /// write the old method back when the second save lands.
  Future<void> _pending = Future<void>.value();

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
  Future<void> setMethod(PrayerCalculationMethod method) =>
      _enqueue((config) => config.copyWith(method: method));

  /// Selects [madhab] and persists it.
  Future<void> setMadhab(PrayerMadhab madhab) =>
      _enqueue((config) => config.copyWith(madhab: madhab));

  /// Enables or disables the reminder for [prayer].
  Future<void> setPrayerEnabled(PrayerName prayer, bool enabled) =>
      _enqueue((config) {
        final prayers = <PrayerName>{...config.enabledPrayers};
        if (enabled) {
          prayers.add(prayer);
        } else {
          prayers.remove(prayer);
        }
        return config.copyWith(enabledPrayers: prayers);
      });

  /// Sets the pre-adhan lead time; 0 disables the early reminder.
  Future<void> setPreAdhanMinutes(int minutes) {
    final safe = minutes < 0 ? 0 : (minutes > 60 ? 60 : minutes);
    return _enqueue((config) => config.copyWith(preAdhanMinutes: safe));
  }

  Future<void> _enqueue(PrayerConfig Function(PrayerConfig) update) {
    final next = _pending.then((_) => _apply(update));
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> _apply(PrayerConfig Function(PrayerConfig) update) async {
    final current = state;
    if (current is! PrayerConfigReady) return;
    final next = update(current.config);
    if (next == current.config) return;
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
