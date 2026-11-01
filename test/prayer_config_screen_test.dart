import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_config/prayer_config_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/prayer_config/prayer_config_screen.dart';

import 'support/host.dart';

class _FakeSource implements PrayerConfigSource {
  PrayerConfig _current = PrayerConfig.egyptian;

  @override
  PrayerConfig get current => _current;

  @override
  Stream<PrayerConfig> get changes => const Stream.empty();

  @override
  Future<PrayerConfig> load() async => _current;

  @override
  Future<void> save(PrayerConfig config) async {
    _current = config;
  }
}

void main() {
  testWidgets('lists the methods and persists a selection', (tester) async {
    final source = _FakeSource();
    final cubit = PrayerConfigCubit(source: source);
    await cubit.start();

    await pumpAppHost(
      tester,
      home: BlocProvider<PrayerConfigCubit>.value(
        value: cubit,
        child: const PrayerConfigScreen(),
      ),
    );

    expect(find.text('إعدادات الصلاة'), findsOneWidget);
    expect(find.text('طريقة حساب المواقيت'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsWidgets);

    final ummAlQura = find.text('أم القرى — مكة المكرمة');
    await tester.scrollUntilVisible(ummAlQura, 200);
    await tester.tap(ummAlQura);
    await tester.pump();

    expect(source.current.method, PrayerCalculationMethod.ummAlQura);

    await tester.scrollUntilVisible(find.text('مذهب العصر'), 200);
    expect(find.text('مذهب العصر'), findsOneWidget);

    final hanafi = find.text('الحنفي');
    await tester.scrollUntilVisible(hanafi, 200);
    await tester.tap(hanafi);
    await tester.pump();

    expect(source.current.madhab, PrayerMadhab.hanafi);
  });
}
