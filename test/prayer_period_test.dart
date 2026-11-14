import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/prayer_period_controller.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_period.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';

const _cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.04,
  lng: 31.24,
);
const _tokyo = City(
  id: 'tokyo',
  nameAr: 'طوكيو',
  nameEn: 'Tokyo',
  lat: 35.68,
  lng: 139.69,
);

// One ordinary day.
final _fajr = DateTime(2026, 11, 14, 5);
final _sunrise = DateTime(2026, 11, 14, 6, 15);
final _dhuhr = DateTime(2026, 11, 14, 11, 50);
final _asr = DateTime(2026, 11, 14, 15, 5);
final _maghrib = DateTime(2026, 11, 14, 17, 40);
final _isha = DateTime(2026, 11, 14, 19, 5);
final _nextFajr = DateTime(2026, 11, 15, 5);

PrayerName _periodAt(
  DateTime now, {
  DateTime? sunrise,
  bool hasSunrise = true,
}) =>
    prayerPeriodAt(
      now: now,
      fajr: _fajr,
      sunrise: hasSunrise ? (sunrise ?? _sunrise) : null,
      dhuhr: _dhuhr,
      asr: _asr,
      maghrib: _maghrib,
      isha: _isha,
    );

DateTime? _nextAt(
  DateTime now, {
  DateTime? sunrise,
  bool hasSunrise = true,
}) =>
    nextPeriodBoundary(
      now: now,
      fajr: _fajr,
      sunrise: hasSunrise ? (sunrise ?? _sunrise) : null,
      dhuhr: _dhuhr,
      asr: _asr,
      maghrib: _maghrib,
      isha: _isha,
      nextFajr: _nextFajr,
    );

class _Times implements PrayerTimesPort {
  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime day) {
    // Six hours apart per city, so a city change actually moves a boundary.
    final shift = c.latitude > 32 ? const Duration(hours: 6) : Duration.zero;
    DateTime at(int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute).add(shift);
    return [
      PrayerChoice(PrayerName.fajr, at(5, 0)),
      PrayerChoice(PrayerName.sunrise, at(6, 15)),
      PrayerChoice(PrayerName.dhuhr, at(11, 50)),
      PrayerChoice(PrayerName.asr, at(15, 5)),
      PrayerChoice(PrayerName.maghrib, at(17, 40)),
      PrayerChoice(PrayerName.isha, at(19, 5)),
    ];
  }

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) =>
      throw UnimplementedError();
}

class _CitySource implements CitySource {
  _CitySource(this._resolve);

  Future<City?> Function() _resolve;

  set resolver(Future<City?> Function() resolve) => _resolve = resolve;

  @override
  Future<City?> selectedCity() => _resolve();

  @override
  Future<void> select(City city) async {}
}

class _ConfigSource implements PrayerConfigSource {
  final StreamController<PrayerConfig> controller =
      StreamController<PrayerConfig>.broadcast();

  @override
  PrayerConfig get current => PrayerConfig.egyptian;

  @override
  Stream<PrayerConfig> get changes => controller.stream;

  @override
  Future<PrayerConfig> load() async => current;

  @override
  Future<void> save(PrayerConfig config) async {}
}

void main() {
  group('prayerPeriodAt', () {
    test('maps every window of a normal day', () {
      expect(_periodAt(DateTime(2026, 11, 14, 0, 30)), PrayerName.isha);
      expect(_periodAt(DateTime(2026, 11, 14, 4, 59)), PrayerName.isha);
      expect(_periodAt(_fajr), PrayerName.fajr);
      expect(_periodAt(_sunrise), PrayerName.sunrise);
      expect(_periodAt(_dhuhr), PrayerName.dhuhr);
      expect(_periodAt(_asr), PrayerName.asr);
      expect(_periodAt(_maghrib), PrayerName.maghrib);
      expect(_periodAt(_isha), PrayerName.isha);
      expect(_periodAt(DateTime(2026, 11, 14, 23, 59)), PrayerName.isha);
    });

    test('isha crosses midnight and ends at the next fajr', () {
      // One minute before tomorrow's fajr it is still last night's isha.
      expect(
        prayerPeriodAt(
          now: DateTime(2026, 11, 15, 4, 59),
          fajr: _nextFajr,
          sunrise: DateTime(2026, 11, 15, 6, 15),
          dhuhr: DateTime(2026, 11, 15, 11, 50),
          asr: DateTime(2026, 11, 15, 15, 5),
          maghrib: DateTime(2026, 11, 15, 17, 40),
          isha: DateTime(2026, 11, 15, 19, 5),
        ),
        PrayerName.isha,
      );
      // At the next fajr the new day starts.
      expect(
        prayerPeriodAt(
          now: _nextFajr,
          fajr: _nextFajr,
          sunrise: DateTime(2026, 11, 15, 6, 15),
          dhuhr: DateTime(2026, 11, 15, 11, 50),
          asr: DateTime(2026, 11, 15, 15, 5),
          maghrib: DateTime(2026, 11, 15, 17, 40),
          isha: DateTime(2026, 11, 15, 19, 5),
        ),
        PrayerName.fajr,
      );
    });

    test('a DST day is still a sequence of instants', () {
      // Egypt 2026-10-29: a local day that is not 24 h long. The markers are
      // instants, so the windows are unchanged; only their spacing moves.
      final fajr = DateTime.utc(2026, 10, 29, 3);
      final sunrise = DateTime.utc(2026, 10, 29, 4, 15);
      final dhuhr = DateTime.utc(2026, 10, 29, 9, 50);
      final asr = DateTime.utc(2026, 10, 29, 13, 5);
      final maghrib = DateTime.utc(2026, 10, 29, 15, 40);
      final isha = DateTime.utc(2026, 10, 29, 17, 5);
      final nextFajr = DateTime.utc(2026, 10, 30, 4);

      expect(
        prayerPeriodAt(
          now: DateTime.utc(2026, 10, 29, 22, 30),
          fajr: fajr,
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: isha,
        ),
        PrayerName.isha,
      );
      // The next boundary is tomorrow's fajr, not a walk over 25 hours.
      expect(
        nextPeriodBoundary(
          now: DateTime.utc(2026, 10, 29, 22, 30),
          fajr: fajr,
          sunrise: sunrise,
          dhuhr: dhuhr,
          asr: asr,
          maghrib: maghrib,
          isha: isha,
          nextFajr: nextFajr,
        ),
        nextFajr,
      );
    });

    test('the same instant is the same period in any offset', () {
      final asTwo = DateTime.parse('2026-11-14T20:40:00+02:00');
      final asUtc = DateTime.parse('2026-11-14T18:40:00Z');
      expect(asTwo.isAtSameMomentAs(asUtc), isTrue);
      // 17:40Z is maghrib in the marker set (which is local on this machine);
      // express both through the marker's own zone so the test is location
      // independent.
      final nowUtc = _maghrib.toUtc().add(const Duration(minutes: 5));
      expect(_periodAt(nowUtc), PrayerName.maghrib);
      expect(_periodAt(nowUtc.toLocal()), PrayerName.maghrib);
    });

    test('a plan without sunrise runs fajr until dhuhr', () {
      expect(
        _periodAt(DateTime(2026, 11, 14, 10), hasSunrise: false),
        PrayerName.fajr,
      );
      // A degenerate sunrise (not before dhuhr) is the same case.
      expect(
        _periodAt(DateTime(2026, 11, 14, 10),
            sunrise: DateTime(2026, 11, 14, 13)),
        PrayerName.fajr,
      );
      expect(
        _periodAt(DateTime(2026, 11, 14, 12), hasSunrise: false),
        PrayerName.dhuhr,
      );
    });

    test('a high-latitude day whose maghrib equals isha has no maghrib window',
        () {
      expect(_periodAt(_maghrib), PrayerName.maghrib);
      // With maghrib == isha the maghrib window is empty: 18:00 is still asr,
      // and the isha palette starts at 19:05.
      expect(
        prayerPeriodAt(
          now: DateTime(2026, 11, 14, 18),
          fajr: _fajr,
          sunrise: _sunrise,
          dhuhr: _dhuhr,
          asr: _asr,
          maghrib: _isha,
          isha: _isha,
        ),
        PrayerName.asr,
      );
      expect(
        prayerPeriodAt(
          now: _isha,
          fajr: _fajr,
          sunrise: _sunrise,
          dhuhr: _dhuhr,
          asr: _asr,
          maghrib: _isha,
          isha: _isha,
        ),
        PrayerName.isha,
      );
    });
  });

  group('nextPeriodBoundary', () {
    test('returns the next marker, including sunrise', () {
      expect(_nextAt(DateTime(2026, 11, 14, 5, 30)), _sunrise);
      expect(_nextAt(DateTime(2026, 11, 14, 7)), _dhuhr);
      expect(_nextAt(DateTime(2026, 11, 14, 18)), _isha);
    });

    test('after isha the boundary is tomorrow fajr', () {
      expect(_nextAt(DateTime(2026, 11, 14, 23, 59)), _nextFajr);
    });

    test('skips the sunrise window when there is none', () {
      expect(_nextAt(DateTime(2026, 11, 14, 5, 30), hasSunrise: false), _dhuhr);
    });

    test('a boundary exactly at now is skipped', () {
      expect(_nextAt(_fajr), _sunrise);
    });
  });

  group('PrayerPeriodController', () {
    late DateTime clock;
    late _Times times;
    late _CitySource city;
    late _ConfigSource config;
    late StreamController<City> cityChanges;
    late List<({Duration delay, void Function() fire})> timers;

    PrayerPeriodController build() {
      final controller = PrayerPeriodController(
        city: city,
        times: times,
        config: config,
        cityChanges: cityChanges.stream,
        now: () => clock,
        schedule: (delay, fire) {
          timers.add((delay: delay, fire: fire));
          // Never fires: the tests drive `fire` themselves.
          return Timer(const Duration(days: 3650), () {});
        },
      );
      addTearDown(controller.dispose);
      return controller;
    }

    setUp(() {
      clock = DateTime(2026, 11, 14, 7);
      times = _Times();
      city = _CitySource(() async => _cairo);
      config = _ConfigSource();
      cityChanges = StreamController<City>.broadcast();
      timers = [];
    });

    tearDown(() async {
      await config.controller.close();
      await cityChanges.close();
    });

    test('computes the period and sleeps to the next boundary', () async {
      final controller = build();
      await controller.refresh();

      expect(controller.period, PrayerName.sunrise);
      expect(timers, hasLength(1));
      // 07:00 is inside the sunrise window -> dhuhr 11:50, plus the 1 s guard.
      expect(
        timers.single.delay,
        const Duration(hours: 4, minutes: 50, seconds: 1),
      );
    });

    test('just after midnight is isha', () async {
      clock = DateTime(2026, 11, 14, 0, 30);
      final controller = build();
      await controller.refresh();

      expect(controller.period, PrayerName.isha);
      expect(timers.single.delay,
          const Duration(hours: 4, minutes: 30, seconds: 1));
    });

    test('a device that slept across several boundaries jumps to the right one',
        () async {
      final controller = build();
      await controller.refresh();
      expect(controller.period, PrayerName.sunrise);

      // Woke at 18:00: crossed dhuhr, asr and maghrib while asleep.
      clock = DateTime(2026, 11, 14, 18);
      await controller.refresh();

      expect(controller.period, PrayerName.maghrib);
      expect(timers, hasLength(2)); // One new timer, not one per boundary.
      expect(
        timers.last.delay,
        const Duration(hours: 1, minutes: 5, seconds: 1),
      );
    });

    test('two rapid plan changes settle on the last one', () async {
      clock = DateTime(2026, 11, 14, 12, 30);
      final slow = Completer<City?>();
      final fast = Completer<City?>();
      var call = 0;
      city.resolver = () {
        call++;
        return call == 1 ? slow.future : fast.future;
      };

      final controller = build();
      final first = controller.refresh();
      final second = controller.refresh();

      fast.complete(_tokyo);
      await second;
      expect(controller.period, PrayerName.sunrise); // Tokyo: 12:15 sunrise.

      // The earlier (Cairo) read lands afterwards and must not win.
      slow.complete(_cairo);
      await first;
      expect(controller.period, PrayerName.sunrise);
      expect(timers, hasLength(1));
    });

    test('a plan change refreshes through the config stream', () async {
      final controller = build();
      controller.start();
      await pumpEventQueue();
      expect(controller.period, PrayerName.sunrise);

      clock = DateTime(2026, 11, 14, 16);
      config.controller.add(PrayerConfig.egyptian);
      await pumpEventQueue();

      expect(controller.period, PrayerName.asr);
    });

    test('a city change refreshes through the city stream', () async {
      final controller = build();
      controller.start();
      await pumpEventQueue();
      expect(controller.period, PrayerName.sunrise);

      // 18:00 in Tokyo is still dhuhr; in Cairo it would be maghrib.
      clock = DateTime(2026, 11, 14, 18);
      city.resolver = () async => _tokyo;
      cityChanges.add(_tokyo);
      await pumpEventQueue();

      expect(controller.period, PrayerName.dhuhr);
    });

    test('a missing or unreadable city holds the last period', () async {
      final controller = build();
      await controller.refresh();
      expect(controller.period, PrayerName.sunrise);

      city.resolver = () async => null;
      await controller.refresh();
      expect(controller.period, PrayerName.sunrise);

      city.resolver = () async => throw StateError('db closed');
      await controller.refresh();
      expect(controller.period, PrayerName.sunrise);
    });

    test('a refresh after dispose is harmless', () async {
      final controller = PrayerPeriodController(
        city: city,
        times: times,
        config: config,
        cityChanges: cityChanges.stream,
        now: () => clock,
        schedule: (delay, fire) => Timer(const Duration(days: 3650), () {}),
      );
      await controller.refresh();
      controller.dispose();

      await controller.refresh(); // Must not throw or notify.
    });

    test('stop cancels the timer and keeps the period; start re-arms it',
        () async {
      Timer? armed;
      final controller = PrayerPeriodController(
        city: city,
        times: times,
        config: config,
        cityChanges: cityChanges.stream,
        now: () => clock,
        schedule: (delay, fire) {
          armed = Timer(const Duration(days: 3650), () {});
          return armed!;
        },
      );
      addTearDown(controller.dispose);

      controller.start();
      await pumpEventQueue();
      expect(controller.period, PrayerName.sunrise);
      expect(armed?.isActive, isTrue);

      controller.stop();
      controller.stop(); // Idempotent.
      expect(armed?.isActive, isFalse);
      expect(controller.period, PrayerName.sunrise); // The last period is kept.

      controller.start();
      await pumpEventQueue();
      expect(armed?.isActive, isTrue);
    });

    test('without a city stream start still computes', () async {
      final controller = PrayerPeriodController(
        city: city,
        times: times,
        config: config,
        now: () => clock,
        schedule: (delay, fire) {
          timers.add((delay: delay, fire: fire));
          return Timer(const Duration(days: 3650), () {});
        },
      );
      addTearDown(controller.dispose);

      controller.start();
      await pumpEventQueue();

      expect(controller.period, PrayerName.sunrise);
      expect(timers, hasLength(1));
    });

    test('dispose cancels the city subscription', () async {
      final events = StreamController<City>.broadcast();
      addTearDown(events.close);
      final controller = PrayerPeriodController(
        city: city,
        times: times,
        config: config,
        cityChanges: events.stream,
        now: () => clock,
        schedule: (delay, fire) => Timer(const Duration(days: 3650), () {}),
      );

      controller.start();
      await pumpEventQueue();
      expect(events.hasListener, isTrue);

      controller.dispose();

      expect(events.hasListener, isFalse);
      // A late event after dispose reaches nobody (no throw, no rebuild).
      events.add(_tokyo);
      await pumpEventQueue();
      expect(controller.period, PrayerName.sunrise);
    });
  });
}
