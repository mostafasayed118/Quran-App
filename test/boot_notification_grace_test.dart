import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/app/app.dart';
import 'package:quran_yahdi/app/bootstrap.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/notifications/data/notifications_binding.dart';
import 'package:quran_yahdi/features/notifications/data/reminder_planner.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  final String path;

  _TempSupportPathProvider(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shouldRequestBootPermission (pure grace matrix)', () {
    test('asks only when notifications are off AND azkar opted in', () {
      expect(
        shouldRequestBootPermission(
            notificationsEnabled: false, azkarEnabled: true),
        isTrue,
      );
    });
    test('never asks the opted-out user', () {
      expect(
        shouldRequestBootPermission(
            notificationsEnabled: false, azkarEnabled: false),
        isFalse,
      );
    });
    test('never asks when notifications are already granted', () {
      expect(
        shouldRequestBootPermission(
            notificationsEnabled: true, azkarEnabled: true),
        isFalse,
      );
    });
    test('never asks when the OS state is unknown', () {
      expect(
        shouldRequestBootPermission(
            notificationsEnabled: null, azkarEnabled: true),
        isFalse,
      );
    });
  });

  testWidgets('notification tap response default-launches to /home',
      (tester) async {
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_boot_grace');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
    await configureDependencies(
      audioRootResolver: defaultAudioRootResolver,
      citiesLoader: defaultCitiesLoader,
    );

    await tester.pumpWidget(const QuranYahdiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeScreen), findsOneWidget);

    AppRouter.router.go('/zakat');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ZakatScreen), findsOneWidget);

    final binding = NotificationsBinding();
    await binding.init(onTap: () => AppRouter.router.go('/home'));
    binding.onNotificationTap(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ZakatScreen), findsNothing);
  });
}
