import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_screen.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_state.dart';

import 'support/host.dart';

class _CrashingLoadRepo extends PrayerLogRepository {
  _CrashingLoadRepo(super.db);

  @override
  Future<TrackerDay> dayView(DateTime day) async => throw StateError('boom');
}

class _CrashingToggleRepo extends PrayerLogRepository {
  _CrashingToggleRepo(super.db);

  @override
  Future<void> togglePrayer(DateTime day, PrayerSlot slot) async =>
      throw StateError('boom');
}

void main() {
  test('a data-layer crash maps to TrackerFailed; loaded still completes',
      () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    final cubit = TrackerCubit(repo: _CrashingLoadRepo(db));
    await cubit.start();
    await cubit.loaded;
    expect(cubit.state, isA<TrackerFailed>());
    await cubit.close();
    await db.close();
  });

  test('a toggle crash is swallowed; the ready state survives', () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    final cubit = TrackerCubit(repo: _CrashingToggleRepo(db));
    await cubit.start();
    await cubit.loaded;
    await cubit.toggle(PrayerSlot.fajr);
    final ready = cubit.state as TrackerReady;
    expect(ready.today.fajr, isFalse);
    await cubit.close();
    await db.close();
  });

  testWidgets('a load crash shows the error pane, not an eternal spinner',
      (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final cubit = TrackerCubit(repo: _CrashingLoadRepo(db));
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<TrackerCubit>.value(
      value: cubit,
      child: appShell(home: const TrackerScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
  });
}
