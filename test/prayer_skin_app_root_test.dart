import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:quran_yahdi/app/app.dart';
import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/prayer_period_controller.dart';
import 'package:quran_yahdi/app/splash_screen.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_skin.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/theme/prayer_palette.dart';
import 'package:quran_yahdi/core/theme/prayer_skin_controller.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

int _hex(Color color) => color.toARGB32();

const _cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_skin_root');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  setUp(() async {
    await configureDependencies(
      audioRootResolver: defaultAudioRootResolver,
      citiesLoader: () async => const <Map<String, dynamic>>[],
    );
    await getIt<CitySource>().select(_cairo);
  });

  tearDown(() async {
    // Drift keeps the file handle open; the temp dir cannot be deleted under
    // it on Windows.
    await getIt<AppDatabase>().close();
    await getIt.reset();
    resetDependenciesForTest();
  });

  testWidgets('the root repaints when the period lands and restores when fixed',
      (tester) async {
    final skin = getIt<PrayerSkinController>();
    final period = getIt<PrayerPeriodController>();
    addTearDown(() => skin.setMode(PrayerSkinMode.fixed));

    await tester.pumpWidget(const QuranYahdiApp());
    await tester.pump();

    // Follow is enabled while the period is still unknown (the refresh is
    // async), which is exactly the ordering that exposed the stale-capture bug
    // on a device. The controller reads a real database and runs the adhan
    // math, so it must run outside the widget test's fake clock: awaiting it
    // inside `pumpEventQueue` deadlocks the fake timer queue.
    final appBefore = tester.widget<MaterialApp>(find.byType(MaterialApp));
    var periodNotifies = 0;
    period.addListener(() => periodNotifies++);

    await tester.runAsync(() async {
      await skin.setMode(PrayerSkinMode.follow);
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (period.period == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    // One frame applies the new theme and starts MaterialApp's 400 ms lerp;
    // the next frames finish it.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    final computed = period.period;
    expect(computed, isNotNull);
    expect(periodNotifies, greaterThan(0), reason: 'the period never notified');
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(identical(appBefore, app), isFalse,
        reason: 'the root builder never re-ran');
    final paletteTheme = AppTheme.forPrayer(computed!, Brightness.light);
    expect(_hex(app.theme!.colorScheme.surfaceTint),
        _hex(paletteTheme.colorScheme.surfaceTint),
        reason: 'MaterialApp did not receive the palette theme');
    final followed = Theme.of(tester.element(find.byType(SplashScreen)));
    final palette = PrayerPalettes.of(computed, followed.brightness);
    expect(_hex(followed.colorScheme.surfaceTint), _hex(palette.primary));
    expect(
      _hex(followed.colorScheme.onSurfaceVariant),
      _hex(palette.muted),
    );

    // The rollback path: fixed is the shipped theme, role for role.
    await tester.runAsync(() async {
      await skin.setMode(PrayerSkinMode.fixed);
    });
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    final shipped = Theme.of(tester.element(find.byType(SplashScreen)));
    expect(
      _hex(shipped.colorScheme.surfaceTint),
      _hex(AppTheme.light.colorScheme.surfaceTint),
    );
    expect(
      _hex(shipped.scaffoldBackgroundColor),
      _hex(AppTheme.light.scaffoldBackgroundColor),
    );
    expect(period.period, computed); // stop() keeps the last period
  });
}
