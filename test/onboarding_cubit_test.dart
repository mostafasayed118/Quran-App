import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/onboarding_status.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/onboarding/presentation/onboarding_cubit.dart';
import 'package:quran_yahdi/features/onboarding/presentation/onboarding_state.dart';

class _City implements CitySource {
  _City({this.city});

  City? city;

  @override
  Future<City?> selectedCity() async => city;

  @override
  Future<void> select(City value) async {
    city = value;
  }
}

class _Status implements OnboardingStatusSource {
  _Status({this.completed = false});

  bool completed;
  bool throwOnRead = false;
  bool throwOnWrite = false;
  int writes = 0;

  @override
  Future<bool> isCompleted() async {
    if (throwOnRead) throw StateError('read');
    return completed;
  }

  @override
  Future<void> markCompleted() async {
    if (throwOnWrite) throw StateError('write');
    writes++;
    completed = true;
  }
}

class _Scheduler implements ReminderSchedulerPort {
  _Scheduler({this.granted = true, this.throwOnRequest = false});

  bool granted;
  bool throwOnRequest;
  int requests = 0;

  @override
  Future<bool> ensurePermissions() async {
    requests++;
    if (throwOnRequest) throw StateError('permission');
    return granted;
  }

  @override
  Future<void> scheduleAll(List<ScheduledReminder> reminders) async {}
}

const _cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

OnboardingCubit _cubit({
  CitySource? city,
  OnboardingStatusSource? status,
  ReminderSchedulerPort? reminders,
}) =>
    OnboardingCubit(
      city: city ?? _City(),
      status: status ?? _Status(),
      reminders: reminders ?? _Scheduler(),
    );

void main() {
  test('no city yet: the city step is open', () async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await cubit.start();

    final state = cubit.state as OnboardingReady;
    expect(state.citySelected, isFalse);
    expect(state.cityName, isNull);
    expect(state.completed, isFalse);
  });

  test('a selected city marks the step done and shows its name', () async {
    final cubit = _cubit(city: _City(city: _cairo));
    addTearDown(cubit.close);
    await cubit.start();

    final state = cubit.state as OnboardingReady;
    expect(state.citySelected, isTrue);
    expect(state.cityName, 'القاهرة');
  });

  test('an already completed flag short-circuits the flow', () async {
    final status = _Status(completed: true);
    final cubit = _cubit(status: status);
    addTearDown(cubit.close);
    await cubit.start();

    expect((cubit.state as OnboardingReady).completed, isTrue);
  });

  test('a granted permission marks the reminder step done', () async {
    final scheduler = _Scheduler(granted: true);
    final cubit = _cubit(reminders: scheduler);
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.requestReminders();

    expect((cubit.state as OnboardingReady).remindersGranted, isTrue);
    expect(scheduler.requests, 1);
  });

  test('a denied or throwing request leaves the step open without crashing',
      () async {
    final denied = _Scheduler(granted: false);
    final cubit = _cubit(reminders: denied);
    addTearDown(cubit.close);
    await cubit.start();
    await cubit.requestReminders();
    expect((cubit.state as OnboardingReady).remindersGranted, isFalse);

    final throwing = _Scheduler(throwOnRequest: true);
    final other = _cubit(reminders: throwing);
    addTearDown(other.close);
    await other.start();
    await other.requestReminders();
    expect((other.state as OnboardingReady).remindersGranted, isFalse);
  });

  test('finishing stores the flag and emits completed', () async {
    final status = _Status();
    final cubit = _cubit(status: status);
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.finish();

    expect((cubit.state as OnboardingReady).completed, isTrue);
    expect(status.writes, 1);
    expect(status.completed, isTrue);
  });

  test('a failing flag write still completes, so the card stops nagging',
      () async {
    final status = _Status()..throwOnWrite = true;
    final cubit = _cubit(status: status);
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.finish();

    expect((cubit.state as OnboardingReady).completed, isTrue);
  });

  test('an unreadable flag counts as completed (never nag)', () async {
    final status = _Status()..throwOnRead = true;
    final cubit = _cubit(status: status);
    addTearDown(cubit.close);
    await cubit.start();

    expect((cubit.state as OnboardingReady).completed, isTrue);
  });

  test('refreshCity picks up a city selected after the flow opened', () async {
    final city = _City();
    final cubit = _cubit(city: city);
    addTearDown(cubit.close);
    await cubit.start();
    expect((cubit.state as OnboardingReady).citySelected, isFalse);

    await city.select(_cairo);
    await cubit.refreshCity();

    final state = cubit.state as OnboardingReady;
    expect(state.citySelected, isTrue);
    expect(state.cityName, 'القاهرة');
  });

  test('steps are ignored once the flow is completed', () async {
    final scheduler = _Scheduler();
    final cubit = _cubit(
      status: _Status(completed: true),
      reminders: scheduler,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.requestReminders();
    await cubit.finish();

    expect(scheduler.requests, 0);
  });
}
