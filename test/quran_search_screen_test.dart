import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/quran/data/quran_search_source.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _FakeSource implements QuranSearchSource {
  const _FakeSource();

  @override
  Future<QuranSearchPage> search(
    String query, {
    int? afterAyahId,
    int limit = kQuranSearchPageSize,
  }) async =>
      const QuranSearchPage(
        hits: [
          QuranSearchHit(
            ayahId: 10,
            surahId: 2,
            numberInSurah: 3,
            surahNameAr: 'البقرة',
            textImlaei: 'الذين يؤمنون بالغيب ويقيمون الصلاة',
          ),
        ],
        total: 1,
        hasMore: false,
      );
}

Widget _host() => BlocProvider<QuranSearchCubit>(
      create: (_) => QuranSearchCubit(const _FakeSource()),
      child: const QuranSearchScreen(),
    );

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: _host(),
  ));
  await tester.pump();
}

void main() {
  testWidgets('shows a prompt before the query is long enough', (tester) async {
    await _pump(tester);

    expect(find.text('اكتب حرفين على الأقل للبحث في الآيات'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ا');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('اكتب حرفين على الأقل للبحث في الآيات'), findsOneWidget);
  });

  testWidgets('renders a result row with its surah and verse', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'الصلاة');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('الذين يؤمنون بالغيب ويقيمون الصلاة'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('٢:٣'), findsOneWidget);
    expect(find.text('عدد النتائج: ١'), findsOneWidget);
  });
}
