import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_screen.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_state.dart';

import 'support/host.dart';
import 'support/test_db.dart';

class _CrashingToggleRepo extends PrayerLogRepository {
  _CrashingToggleRepo(super.db);

  @override
  Future<void> togglePrayer(DateTime day, PrayerSlot slot) async =>
      throw StateError('boom');
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  Future<TrackerCubit> build() async {
    final cubit = TrackerCubit(repo: _CrashingToggleRepo(db));
    await cubit.start();
    await cubit.loaded;
    return cubit;
  }

  test('a throwing toggle flags the ready state', () async {
    final cubit = await build();

    await cubit.toggle(PrayerSlot.fajr);

    final ready = cubit.state as TrackerReady;
    expect(ready.actionFailed, isTrue);
    expect(ready.today.fajr, isFalse);

    await cubit.close();
  });

  test('acknowledgeActionFailure clears the flag', () async {
    final cubit = await build();
    await cubit.toggle(PrayerSlot.fajr);
    expect((cubit.state as TrackerReady).actionFailed, isTrue);

    cubit.acknowledgeActionFailure();

    expect((cubit.state as TrackerReady).actionFailed, isFalse);
    await cubit.close();
  });

  testWidgets('the screen shows the localized failure snackbar once',
      (tester) async {
    final cubit = await build();
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<TrackerCubit>.value(value: cubit, child: app),
      home: const TrackerScreen(),
    );

    await cubit.toggle(PrayerSlot.fajr);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
    expect((cubit.state as TrackerReady).actionFailed, isFalse);
  });
}
