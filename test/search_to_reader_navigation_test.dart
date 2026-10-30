import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_source.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _OneHitSource implements QuranSearchSource {
  const _OneHitSource();

  @override
  Future<QuranSearchPage> search(
    String query, {
    int? afterAyahId,
    int limit = kQuranSearchPageSize,
  }) async =>
      // QuranSearchPage has no const constructor.
      // ignore: prefer_const_constructors
      QuranSearchPage(
        hits: const [
          QuranSearchHit(
            ayahId: 10,
            surahId: 2,
            numberInSurah: 3,
            surahNameAr: 'البقرة',
            textImlaei: 'الذين يؤمنون بالغيب',
          ),
        ],
        total: 1,
        hasMore: false,
      );
}

void main() {
  testWidgets('tapping a search hit opens the reader at surah:ayah',
      (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.quranSearch,
      routes: [
        GoRoute(
          path: AppRoutes.quranSearch,
          builder: (context, state) => BlocProvider<QuranSearchCubit>(
            create: (_) => QuranSearchCubit(
              const _OneHitSource(),
              debounce: Duration.zero,
            ),
            child: const QuranSearchScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.reader,
          builder: (context, state) => Scaffold(
            body: Text(
              'reader:${state.uri.queryParameters['surah']}:'
              '${state.uri.queryParameters['ayah']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
    ));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'الصلاة');
    await tester.pump();
    await tester.pump();

    expect(find.text('الذين يؤمنون بالغيب'), findsOneWidget);
    await tester.tap(find.text('الذين يؤمنون بالغيب'));
    await tester.pumpAndSettle();

    expect(find.text('reader:2:3'), findsOneWidget);
  });
}
