import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/core/domain/pre_adhan_canceller.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import 'prayer_config_state.dart';

/// The prayer settings screen: calculation method and Asr madhab.
///
/// The constructor is side-effect free; the route scope calls [start] once.
/// Every setter only builds on a confirmed [PrayerConfigReady] and keeps the
/// last saved configuration if the write fails.
class PrayerConfigCubit extends Cubit<PrayerConfigState> {
  /// Creates the cubit over [source].
  PrayerConfigCubit({
    required PrayerConfigSource source,
    PreAdhanCanceller? preAdhanCanceller,
  })  : _source = source,
        _preAdhanCanceller = preAdhanCanceller,
        super(const PrayerConfigState.loading());

  final PrayerConfigSource _source;
  final PreAdhanCanceller? _preAdhanCanceller;

  /// The latest configuration actually persisted, independent of whether the
  /// route is still mounted/emitting. A queued mutation builds on this, so a
  /// closed cubit cannot overwrite an earlier pending selection.
  PrayerConfig? _confirmed;

  /// Serializes overlapping selections so a quick method + madhab tap cannot
  /// write the old method back when the second save lands.
  Future<void> _pending = Future<void>.value();

  /// Loads the persisted configuration.
  Future<void> start() async {
    try {
      final config = await _source.load();
      _confirmed = config;
      if (!isClosed) emit(PrayerConfigState.ready(config));
    } on Object catch (error, stackTrace) {
      appLog('prayer config load failed',
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

  /// Sets the manual minute correction for [prayer]; zero removes the entry.
  Future<void> setAdjustment(PrayerName prayer, int minutes) {
    if (prayer == PrayerName.sunrise) return Future<void>.value();
    final safe = PrayerConfig.clampAdjustment(minutes);
    return _enqueue((config) {
      final next = Map<PrayerName, int>.of(config.adjustments);
      if (safe == 0) {
        next.remove(prayer);
      } else {
        next[prayer] = safe;
      }
      return config.copyWith(adjustments: next);
    });
  }

  /// Adjusts [prayer] by [delta] relative to the stored correction.
  ///
  /// The stepper sends deltas so two taps made before a rebuild both count; an
  /// absolute value computed in build collapses them into one.
  Future<void> adjustBy(PrayerName prayer, int delta) {
    if (prayer == PrayerName.sunrise) return Future<void>.value();
    return _enqueue((config) {
      final next = Map<PrayerName, int>.of(config.adjustments);
      final safe = PrayerConfig.clampAdjustment(
        (config.adjustments[prayer] ?? 0) + delta,
      );
      if (safe == 0) {
        next.remove(prayer);
      } else {
        next[prayer] = safe;
      }
      return config.copyWith(adjustments: next);
    });
  }

  /// Selects the high-latitude rule and persists it.
  Future<void> setHighLatitude(PrayerHighLatitudeRule rule) =>
      _enqueue((config) => config.copyWith(highLatitude: rule));

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

  /// Sets the pre-adhan lead time; 0 disables the early reminder and clears
  /// any alarm left over from a previous run.
  Future<void> setPreAdhanMinutes(int minutes) {
    final safe = minutes < 0 ? 0 : (minutes > 60 ? 60 : minutes);
    final saved = _enqueue((config) => config.copyWith(preAdhanMinutes: safe));
    return saved.then((_) async {
      if (safe == 0 && _confirmed?.preAdhanMinutes == 0) {
        await _preAdhanCanceller?.cancelPreAdhan();
      }
    });
  }

  /// Enables or disables the two Fajr follow-up nudges and persists it.
  Future<void> setFajrFollowUp(bool enabled) =>
      _enqueue((config) => config.copyWith(fajrFollowUp: enabled));

  Future<void> _enqueue(PrayerConfig Function(PrayerConfig) update) {
    final next = _pending.then((_) => _apply(update));
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> _apply(PrayerConfig Function(PrayerConfig) update) async {
    final current = _confirmed;
    if (current == null) return;
    final next = update(current);
    if (next == current) return;
    try {
      await _source.save(next);
      _confirmed = next;
      if (!isClosed) emit(PrayerConfigState.ready(next));
    } on Object catch (error, stackTrace) {
      // Keep the last confirmed state; the screen keeps showing it.
      appLog('prayer config save failed',
          name: 'quran_yahdi/prayer', error: error, stackTrace: stackTrace);
    }
  }
}
