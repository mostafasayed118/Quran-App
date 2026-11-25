// Issue 2 (audit Top 5): malformed feelings deep-link params must render the
// existing localized copy, never hardcoded English. The GoRoute objects are
// taken from the REAL AppRouter configuration, so this exercises the shipped
// builders rather than a copy of their logic.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';

import '../../support/host.dart';

void main() {
  late GoRouter router;

  setUp(() {
    final feelings = AppRouter.router.configuration.routes
        .whereType<GoRoute>()
        .where(
          (r) =>
              r.path == AppRoutes.feelingsVerses ||
              r.path == AppRoutes.feelingsVerse,
        )
        .toList();
    expect(feelings, hasLength(2), reason: 'both feelings routes are present');

    router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        ...feelings,
      ],
    );
    addTearDown(router.dispose);
  });

  testWidgets('invalid feeling param shows localized copy (English)', (
    tester,
  ) async {
    await tester.pumpWidget(
      routedAppShell(router: router, locale: const Locale('en')),
    );

    router.go('${AppRoutes.feelingsVerses}?feeling=nope');
    await tester.pumpAndSettle();

    expect(find.text('The required data is invalid.'), findsOneWidget);
    expect(find.text('Invalid feeling'), findsNothing);
  });

  testWidgets('invalid verse params show localized copy (English)', (
    tester,
  ) async {
    await tester.pumpWidget(
      routedAppShell(router: router, locale: const Locale('en')),
    );

    router.go('${AppRoutes.feelingsVerse}?feeling=qalaq&surah=abc&ayah=28');
    await tester.pumpAndSettle();

    expect(find.text('The required data is invalid.'), findsOneWidget);
    expect(find.text('Invalid verse'), findsNothing);
  });

  testWidgets('invalid params stay localized in Arabic', (tester) async {
    await tester.pumpWidget(
      routedAppShell(router: router, locale: const Locale('ar')),
    );

    router.go('${AppRoutes.feelingsVerses}?feeling=nope');
    await tester.pumpAndSettle();
    expect(find.text('البيانات المطلوبة غير صحيحة.'), findsOneWidget);
    expect(find.text('Invalid feeling'), findsNothing);
  });
}
