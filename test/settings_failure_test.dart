import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_settings.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_state.dart';

import 'prayer_times_cubit_test.dart' show FakePrayerTimeService;
import 'settings_cubit_test.dart' show FakeReminderScheduler;
import 'support/test_db.dart';

class ThrowingReminderSettings extends ReminderSettings {
  ThrowingReminderSettings(super._db);

  @override
  Future<bool> azkarEnabled() async {
    throw StateError('settings read failed');
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  test('a throwing settings read emits loading then failed, never hangs',
      () async {
    final cubit = SettingsCubit(
      settings: ThrowingReminderSettings(db),
      city: CityRepository(
        db: db,
        loader: () async => const <Map<String, dynamic>>[],
      ),
      prayer: FakePrayerTimeService(),
      scheduler: FakeReminderScheduler(),
    );

    expect(cubit.state, isA<SettingsLoading>());

    await cubit.load();

    expect(cubit.state, isA<SettingsFailed>());
    expect(cubit.state, isNot(isA<SettingsLoading>()));

    await cubit.close();
  });
}
