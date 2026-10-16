import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/widgets/placeholder_screen.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  final String path;

  _TempSupportPathProvider(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_404');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  setUp(() async {
    await configureDependencies(
      audioRootResolver: defaultAudioRootResolver,
      citiesLoader: defaultCitiesLoader,
    );
  });

  testWidgets('unknown route lands on the localized 404 page with a way home',
      (tester) async {
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: AppRouter.router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('قرآن يَهدي'), findsOneWidget);

    final homeContext = tester.element(find.byType(HomeScreen));
    GoRouter.of(homeContext).go('/definitely-not-a-route');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('الصفحة غير موجودة'), findsWidgets);
    expect(find.text('الرابط الذي فتحت غير موجود هنا'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
