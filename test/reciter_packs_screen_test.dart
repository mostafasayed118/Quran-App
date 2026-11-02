import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/domain/reciter_pack.dart';
import 'package:quran_yahdi/features/recitation/presentation/packs/reciter_packs_screen.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/host.dart';
import 'support/test_db.dart';

/// The published selection criteria (decision D2), verbatim.
const List<String> _criteria = <String>[
  'صحة الأداء ومخارج الحروف — مراجعة بشرية',
  'اكتمال المصحف (١١٤ سورة)',
  'جودة التسجيل وثباته',
  'تنوّع الأسلوب (مرتل/مجوّد/معلّم)',
  'لا معيار تجاري ولا ترتيب مدفوع',
];

const String _emptyCopy =
    'لا توجد حزمة منشورة بعد — تُنشر أول حزمة بعد توقيع مراجع بشري.';

/// A pack a human signed: three entries, one reason each.
const String _signedTitle = 'تلاوات مرتّلة';
const String _signedDescription = 'ثلاثة قرّاء بأداء مرتّل متقن.';
const String _signedReviewer = 'مراجع تجريبي';
const List<String> _signedReasons = <String>[
  'قارئ أوّل — صوت واضح',
  'قارئ ثانٍ — إتقان في المخارج',
  'قارئ ثالث — ثبات في الإيقاع',
];

const ReciterPack _signedPack = ReciterPack(
  id: 'murattal-classics',
  titleAr: _signedTitle,
  descriptionAr: _signedDescription,
  reviewedBy: _signedReviewer,
  entries: <ReciterPackEntry>[
    ReciterPackEntry(rowId: '1-1', reasonAr: 'قارئ أوّل — صوت واضح'),
    ReciterPackEntry(rowId: '2-2', reasonAr: 'قارئ ثانٍ — إتقان في المخارج'),
    ReciterPackEntry(rowId: '3-3', reasonAr: 'قارئ ثالث — ثبات في الإيقاع'),
  ],
);

/// Same shape as [_signedPack] but nobody attested to it: one defect, and the
/// gate alone has to keep it off the page.
const String _unsignedTitle = 'حزمة غير موقّعة';
const ReciterPack _unsignedPack = ReciterPack(
  id: 'unsigned-pack',
  titleAr: _unsignedTitle,
  descriptionAr: 'لا تظهر: لا مراجع بشري.',
  reviewedBy: '   ',
  entries: <ReciterPackEntry>[
    ReciterPackEntry(rowId: '4-4', reasonAr: 'سبب أوّل'),
    ReciterPackEntry(rowId: '5-5', reasonAr: 'سبب ثانٍ'),
    ReciterPackEntry(rowId: '6-6', reasonAr: 'سبب ثالث'),
  ],
);

/// The page's own list, named.
///
/// `find.byType(Scrollable)` alone matches two scrollables as soon as
/// `EmptyState` (which scrolls internally) is on the page; the list's own
/// scrollable is the outermost descendant, hence `.first`.
Finder _packsScrollable() => find
    .descendant(
      of: find.byKey(const Key('reciterPacksList')),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  testWidgets('publishes the intro, the five criteria and the empty state',
      (tester) async {
    await pumpAppHost(tester, home: const ReciterPacksScreen(packs: []));

    expect(find.byType(ReciterPacksScreen), findsOneWidget);
    expect(find.text('حزم القرّاء'), findsOneWidget);
    expect(
      find.textContaining('قوائم قرّاء مختارة بعناية'),
      findsOneWidget,
    );
    expect(find.text('معايير الانتقاء'), findsOneWidget);
    for (final criterion in _criteria) {
      expect(find.text(criterion), findsOneWidget);
    }
    expect(find.text(_emptyCopy), findsOneWidget);
  });

  testWidgets('a signed pack renders; an unsigned one never appears',
      (tester) async {
    await pumpAppHost(
      tester,
      home: const ReciterPacksScreen(packs: [_signedPack, _unsignedPack]),
    );

    expect(find.text(_signedTitle), findsOneWidget);
    expect(find.text(_signedDescription), findsOneWidget);
    for (final reason in _signedReasons) {
      expect(find.text(reason), findsOneWidget);
    }
    expect(find.text('راجعها: $_signedReviewer'), findsOneWidget);

    // The reviewer gate, not the caller, decides what is published.
    expect(find.text(_unsignedTitle), findsNothing);
    expect(find.text(_emptyCopy), findsNothing);
  });

  testWidgets('renders at textScaler 2.0 without overflowing', (tester) async {
    await pumpAppHost(
      tester,
      home: const ReciterPacksScreen(packs: [_signedPack]),
      textScale: 2.0,
    );

    // Walk the whole page: every published line must lay out at the largest
    // device text size, not just the ones on the first screen.
    for (final copy in <String>[
      ..._criteria,
      _signedTitle,
      _signedDescription,
      ..._signedReasons,
      'راجعها: $_signedReviewer',
    ]) {
      await tester.scrollUntilVisible(
        find.text(copy),
        120,
        scrollable: _packsScrollable(),
      );
      expect(find.text(copy), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the shipping empty state lays out at textScaler 2.0',
      (tester) async {
    // v1 publishes no pack, so this is the screen every reader will see.
    await pumpAppHost(
      tester,
      home: const ReciterPacksScreen(packs: []),
      textScale: 2.0,
    );

    await tester.scrollUntilVisible(
      find.text(_emptyCopy),
      120,
      scrollable: _packsScrollable(),
    );
    expect(find.text(_emptyCopy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the decorative bullet is silent; the copy is still announced',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpAppHost(
        tester,
        home: const ReciterPacksScreen(packs: [_signedPack]),
      );

      // The bullet is decoration: a screen reader must read the criterion, not
      // «•» before every line. The merged node is what carries these lines to
      // TalkBack, so the copy has to be in it exactly as before.
      final criteria = tester.getSemantics(find.text(_criteria.first)).label;
      expect(criteria, contains(_criteria.first));
      expect(criteria, isNot(contains('•')));

      final card = tester.getSemantics(find.text(_signedReasons.first)).label;
      expect(card, contains(_signedReasons.first));
      expect(card, contains('راجعها: $_signedReviewer'));
      expect(card, isNot(contains('•')));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('the reciters AppBar action opens the declared packs route',
      (tester) async {
    final db = newTestDb();
    final cubit = RecitersCubit(repo: _EmptyReciterRepository(db));
    addTearDown(cubit.close);
    await cubit.start();

    // Two routes only: the action must push the DECLARED address, and that
    // address must render the page. The DI-heavy real router would bring the
    // whole locator in for no extra coverage.
    final router = GoRouter(
      initialLocation: AppRoutes.recitation,
      routes: [
        GoRoute(
          path: AppRoutes.recitation,
          builder: (_, __) => BlocProvider<RecitersCubit>.value(
            value: cubit,
            child: const RecitersScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.reciterPacks,
          builder: (_, __) => const ReciterPacksScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    await tester.pumpAndSettle();

    // An action, never a list row: the reciters list must stay row-free for
    // the frozen "no catalog, no list" test to keep passing.
    expect(find.byTooltip('حزم القرّاء'), findsOneWidget);

    await tester.tap(find.byTooltip('حزم القرّاء'));
    await tester.pumpAndSettle();

    expect(find.byType(ReciterPacksScreen), findsOneWidget);
    expect(find.text(_emptyCopy), findsOneWidget);
  });

  testWidgets('the real router serves /recitation/packs', (tester) async {
    // The real router: proves the address is wired, not just the widget.
    AppRouter.router.go(AppRoutes.reciterPacks);
    await tester.pumpWidget(_routerApp(AppRouter.router));
    await tester.pumpAndSettle();

    expect(find.byType(ReciterPacksScreen), findsOneWidget);
    expect(find.text('حزم القرّاء'), findsOneWidget);
  });
}

/// The in-app shell for a router: locale, delegates and the app theme, so a
/// route renders exactly what the app renders.
Widget _routerApp(GoRouter router) => MaterialApp.router(
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
    );

/// A repository with no catalog rows: the screen only needs its AppBar here,
/// so the loading state is enough and nothing is fetched.
class _EmptyReciterRepository extends ReciterRepository {
  _EmptyReciterRepository(super.db);

  @override
  Stream<List<ReciterRow>> watchAll() => Stream.value(const []);
}
