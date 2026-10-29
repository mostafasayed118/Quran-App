import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_state.dart';

import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'settings_mutation_serialization_test.dart' show NoCity, NoPrayer;

/// Records every write so the tests can prove a rejected mutation never
/// reached storage. [failLoad] drives the cubit's load to a failed state.
class RecordingReminderSettings implements ReminderSettingsPort {
  bool failLoad = false;
  bool azkar = false;
  String azkarTime = '04:45';
  bool wird = false;
  String wirdTime = '22:10';
  final writes = <String>[];
  int reschedules = 0;

  @override
  Future<bool> azkarEnabled() async {
    if (failLoad) throw StateError('settings read failed');
    return azkar;
  }

  @override
  Future<String?> azkarTimeHm() async => azkarTime;

  @override
  Future<bool> wirdEnabled() async => wird;

  @override
  Future<String?> wirdTimeHm() async => wirdTime;

  @override
  Future<void> setAzkarEnabled(bool enabled) async {
    writes.add('azkarEnabled:$enabled');
    azkar = enabled;
  }

  @override
  Future<void> setAzkarTime(String hm) async {
    writes.add('azkarTime:$hm');
    azkarTime = hm;
  }

  @override
  Future<void> setWirdEnabled(bool enabled) async {
    writes.add('wirdEnabled:$enabled');
    wird = enabled;
  }

  @override
  Future<void> setWirdTime(String hm) async {
    writes.add('wirdTime:$hm');
    wirdTime = hm;
  }

  @override
  Future<void> reschedule({
    required CitySource city,
    required PrayerTimesPort prayer,
    required ReminderSchedulerPort scheduler,
  }) async {
    reschedules++;
  }
}

/// The separate prayer-toggle seam, recording its writes too.
class RecordingPrayerSettings implements PrayerReminderSettingsPort {
  bool stored = false;
  final writes = <bool>[];

  @override
  Future<bool> prayerEnabled() async => stored;

  @override
  Future<void> setPrayerEnabled(bool enabled) async {
    writes.add(enabled);
    stored = enabled;
  }
}

SettingsCubit buildSettingsCubit({
  required RecordingReminderSettings settings,
  required RecordingPrayerSettings prayerSettings,
  required FakeReminderScheduler scheduler,
}) =>
    SettingsCubit(
      settings: settings,
      prayerSettings: prayerSettings,
      city: NoCity(),
      prayer: NoPrayer(),
      scheduler: scheduler,
    );

/// All seven ready fields, in declaration order.
List<Object?> fields(SettingsReady ready) => [
      ready.prayerEnabled,
      ready.azkarEnabled,
      ready.azkarTimeHm,
      ready.wirdEnabled,
      ready.wirdTimeHm,
      ready.azkarPermissionDenied,
      ready.wirdPermissionDenied,
    ];

void main() {
  test('mutations issued before the load resolves write and emit nothing',
      () async {
    final settings = RecordingReminderSettings();
    final prayerSettings = RecordingPrayerSettings();
    final scheduler = FakeReminderScheduler();
    final cubit = buildSettingsCubit(
      settings: settings,
      prayerSettings: prayerSettings,
      scheduler: scheduler,
    );
    addTearDown(cubit.close);

    final emitted = <SettingsState>[];
    final sub = cubit.stream.listen(emitted.add);
    addTearDown(sub.cancel);

    expect(cubit.state, isA<SettingsLoading>());

    await cubit.setPrayerEnabled(true);
    await cubit.setAzkarEnabled(true);
    await cubit.setTime('05:15');
    await cubit.toggleWird(true);
    await cubit.changeWirdTime('21:45');
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isEmpty);
    expect(cubit.state, isA<SettingsLoading>());
    expect(settings.writes, isEmpty);
    expect(prayerSettings.writes, isEmpty);
    expect(scheduler.permissionCalls, 0);
    expect(settings.reschedules, 0);
  });

  test('a failed load keeps every mutator from inventing a ready state',
      () async {
    final settings = RecordingReminderSettings()..failLoad = true;
    final prayerSettings = RecordingPrayerSettings();
    final scheduler = FakeReminderScheduler();
    final cubit = buildSettingsCubit(
      settings: settings,
      prayerSettings: prayerSettings,
      scheduler: scheduler,
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state, isA<SettingsFailed>());

    final emitted = <SettingsState>[];
    final sub = cubit.stream.listen(emitted.add);
    addTearDown(sub.cancel);

    await cubit.setPrayerEnabled(true);
    await cubit.setAzkarEnabled(true);
    await cubit.setTime('05:15');
    await cubit.toggleWird(true);
    await cubit.changeWirdTime('21:45');
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isEmpty);
    expect(cubit.state, isA<SettingsFailed>());
    expect(settings.writes, isEmpty);
    expect(prayerSettings.writes, isEmpty);
    expect(scheduler.permissionCalls, 0);
    expect(settings.reschedules, 0);
  });

  test('a ready cubit emits once per mutation and preserves every other field',
      () async {
    final settings = RecordingReminderSettings();
    final prayerSettings = RecordingPrayerSettings();
    final scheduler = FakeReminderScheduler()..permissionsResult = false;
    final cubit = buildSettingsCubit(
      settings: settings,
      prayerSettings: prayerSettings,
      scheduler: scheduler,
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect(
      fields(cubit.state as SettingsReady),
      [false, false, '04:45', false, '22:10', false, false],
    );

    final emitted = <SettingsState>[];
    final sub = cubit.stream.listen(emitted.add);
    addTearDown(sub.cancel);

    Future<SettingsReady> mutate(Future<void> Function() op) async {
      emitted.clear();
      await op();
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));
      return emitted.single as SettingsReady;
    }

    // Each step flips exactly the fields it owns; the denied flags go true
    // with the first enable (the fake denies permissions) and must survive
    // every later mutation.
    expect(
      fields(await mutate(() => cubit.setPrayerEnabled(true))),
      [true, false, '04:45', false, '22:10', false, false],
    );
    expect(
      fields(await mutate(() => cubit.setAzkarEnabled(true))),
      [true, true, '04:45', false, '22:10', true, false],
    );
    expect(
      fields(await mutate(() => cubit.setTime('05:15'))),
      [true, true, '05:15', false, '22:10', true, false],
    );
    expect(
      fields(await mutate(() => cubit.toggleWird(true))),
      [true, true, '05:15', true, '22:10', true, true],
    );
    expect(
      fields(await mutate(() => cubit.changeWirdTime('21:45'))),
      [true, true, '05:15', true, '21:45', true, true],
    );

    expect(
      settings.writes,
      [
        'azkarEnabled:true',
        'azkarTime:05:15',
        'wirdEnabled:true',
        'wirdTime:21:45'
      ],
    );
    expect(prayerSettings.writes, [true]);
  });
}
