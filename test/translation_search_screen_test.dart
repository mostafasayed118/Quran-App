import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/library/data/translation_search_source.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/search/translation_search_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _Source implements TranslationSearchSource {
  _Source(this.indexes);

  final Map<String, Map<int, String>> indexes;

  @override
  Future<List<String>> installedTranslationIds() async =>
      indexes.keys.toList(growable: false);

  @override
  Future<Map<int, String>> translationIndex(String packId) async =>
      indexes[packId] ?? const <int, String>{};
}

Widget _app(TranslationSearchCubit cubit) => BlocProvider.value(
      value: cubit,
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TranslationSearchScreen(),
      ),
    );

void main() {
  testWidgets('typing a query renders the matching translation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = TranslationSearchCubit(
      source: _Source({
        'en1': {1001: 'In the name of Allah, the Entirely Merciful'},
      }),
      surahName: (id) async => 'الفاتحة',
      debounce: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'merciful');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('١ نتيجة'), findsOneWidget);
    expect(find.text('الفاتحة · ١'), findsOneWidget);
    expect(find.textContaining('Entirely Merciful'), findsOneWidget);
  });

  testWidgets('no installed translation shows the install hint',
      (tester) async {
    final cubit = TranslationSearchCubit(
      source: _Source(const {}),
      surahName: (id) async => null,
      debounce: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(
      find.text('لا توجد ترجمة مثبتة. ثبّت ترجمة من المكتبة أولًا.'),
      findsOneWidget,
    );
  });

  testWidgets('no match shows the no-results state', (tester) async {
    final cubit = TranslationSearchCubit(
      source: _Source({
        'en1': {1001: 'mercy'},
      }),
      surahName: (id) async => 'الفاتحة',
      debounce: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_app(cubit));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });
}
