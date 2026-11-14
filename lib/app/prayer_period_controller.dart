import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/domain/city.dart';
import '../core/domain/prayer_config.dart';
import '../core/domain/prayer_period.dart';
import '../core/domain/prayer_times.dart';
import '../core/utils/app_log.dart';

/// Schedules the next period boundary; injectable so tests never wait.
typedef PeriodTimerFactory = Timer Function(
  Duration delay,
  void Function() fire,
);

/// Derives the current prayer period for the prayer skin and re-derives it at
/// every boundary.
///
/// The controller owns no UI and no palette: it answers "which period is it?"
/// and notifies. It recomputes from scratch on every trigger (a timer firing,
/// `AppLifecycleState.resumed`, a plan change, a city change) instead of
/// walking forward one boundary at a time — that is what makes a phone that
/// slept through four boundaries land on the right period immediately, and
/// what keeps DST and time-zone changes from needing their own code.
///
/// A failed read or a missing city **holds the last known period**; it never
/// reports "no plan" and never throws into the boot path.
class PrayerPeriodController extends ChangeNotifier {
  /// Creates the controller over the city selection and the configured times.
  PrayerPeriodController({
    required CitySource city,
    required PrayerTimesPort times,
    required PrayerConfigSource config,
    Stream<City>? cityChanges,
    DateTime Function()? now,
    PeriodTimerFactory? schedule,
  })  : _city = city,
        _times = times,
        _config = config,
        _cityChanges = cityChanges,
        _now = now ?? DateTime.now,
        _schedule = schedule ?? ((delay, fire) => Timer(delay, fire));

  final CitySource _city;
  final PrayerTimesPort _times;
  final PrayerConfigSource _config;
  final Stream<City>? _cityChanges;
  final DateTime Function() _now;
  final PeriodTimerFactory _schedule;

  PrayerName? _period;
  Timer? _timer;
  StreamSubscription<PrayerConfig>? _configSubscription;
  StreamSubscription<City>? _citySubscription;
  int _generation = 0;
  bool _disposed = false;

  /// The period in effect, or null until the first successful computation.
  PrayerName? get period => _period;

  /// Starts observing the plan and the city and computes the first period.
  ///
  /// Idempotent: the app root calls it once per `follow` selection, and the
  /// subscriptions are only created the first time.
  void start() {
    _configSubscription ??= _config.changes.listen(
      (_) => unawaited(refresh()),
    );
    _citySubscription ??= _cityChanges?.listen(
      (_) => unawaited(refresh()),
    );
    unawaited(refresh());
  }

  /// Recomputes the period and re-arms the timer.
  ///
  /// Safe to call at any time; overlapping calls settle on the **last** one
  /// (a rapid plan/city change cannot be overwritten by a slower earlier
  /// read).
  Future<void> refresh() async {
    final generation = ++_generation;
    _timer?.cancel();
    _timer = null;
    try {
      final city = await _city.selectedCity();
      if (_disposed || generation != _generation) return;
      if (city == null) return; // Hold the last period until a city exists.

      final now = _now();
      final day = DateTime(now.year, now.month, now.day);
      final coordinates = CityCoordinates(city.lat, city.lng);
      final today = _markers(coordinates, day);
      final tomorrow = _markers(
        coordinates,
        DateTime(day.year, day.month, day.day + 1),
      );

      final fajr = today[PrayerName.fajr];
      final dhuhr = today[PrayerName.dhuhr];
      final asr = today[PrayerName.asr];
      final maghrib = today[PrayerName.maghrib];
      final isha = today[PrayerName.isha];
      final nextFajr = tomorrow[PrayerName.fajr];
      if (fajr == null ||
          dhuhr == null ||
          asr == null ||
          maghrib == null ||
          isha == null ||
          nextFajr == null) {
        return; // A partial day holds the last period.
      }
      final sunrise = today[PrayerName.sunrise];

      final period = prayerPeriodAt(
        now: now,
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
      );
      final next = nextPeriodBoundary(
        now: now,
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        nextFajr: nextFajr,
      );

      if (_period != period) {
        _period = period;
        notifyListeners();
      }
      if (!_disposed && next != null) _arm(next, now);
    } on Object catch (error, stackTrace) {
      appLog(
        'prayer period refresh failed',
        name: 'quran_yahdi/theme',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<PrayerName, DateTime> _markers(CityCoordinates c, DateTime day) {
    return {
      for (final choice in _times.today(c, day)) choice.name: choice.time,
    };
  }

  void _arm(DateTime next, DateTime now) {
    // +1 s: the timer may fire a hair before the marker, and re-arming on the
    // same instant would spin.
    final delay = next.difference(now) + const Duration(seconds: 1);
    _timer = _schedule(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(refresh()),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_configSubscription?.cancel());
    unawaited(_citySubscription?.cancel());
    super.dispose();
  }
}
