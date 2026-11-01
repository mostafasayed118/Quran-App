import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/widgets/empty_state.dart';
import 'package:quran_yahdi/core/widgets/loading_and_error_views.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_screen.dart';

import 'support/host.dart';

/// Serves a canned page so every state arm is reachable without a pack file.
class _CannedPageDownloader extends PackDownloader {
  _CannedPageDownloader(
    super.db, {
    this.items = const [],
    this.hasMore = false,
  });

  final List<(int, String)> items;
  final bool hasMore;

  @override
  Future<(List<(int, String)>, bool)> hadithPage(
          String packId, int offset, int limit) async =>
      (items, hasMore);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedPack({
    String packId = 'ar-bukhari',
    String language = 'ar',
    String title = 'صحيح البخاري',
  }) async {
    await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
          packId: packId,
          kind: 'hadith',
          language: language,
          title: title,
          sizeMb: 4.2,
          version: '1',
        ));
  }

  Future<HadithCubit> pumpScreen(
    WidgetTester tester, {
    required PackDownloader downloader,
    String packId = 'ar-bukhari',
    bool start = true,
    double? textScale,
  }) async {
    final cubit = HadithCubit(downloader: downloader, packId: packId);
    addTearDown(cubit.close);
    if (start) await cubit.start();
    await tester.pumpWidget(appShell(
      textScale: textScale,
      home: BlocProvider<HadithCubit>.value(
        value: cubit,
        child: const HadithScreen(),
      ),
    ));
    await tester.pump();
    return cubit;
  }

  testWidgets('empty pack renders the empty state and no pager',
      (tester) async {
    await seedPack();
    await pumpScreen(tester, downloader: _CannedPageDownloader(db));

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('لا توجد أحاديث في هذه الحزمة'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.text('التالي'), findsNothing);
    expect(find.text('السابق'), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('loading renders the shared LoadingView', (tester) async {
    await pumpScreen(
      tester,
      start: false,
      downloader: _CannedPageDownloader(db),
    );

    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('language chip shows the localized name, not the raw code',
      (tester) async {
    await seedPack();
    await pumpScreen(
      tester,
      downloader: _CannedPageDownloader(
        db,
        items: const [(1, 'حديثٌ أوّل')],
      ),
    );

    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('AR'), findsNothing);
  });

  testWidgets('unknown language codes fall back to the raw code',
      (tester) async {
    await seedPack(packId: 'ur-pack', language: 'ur', title: 'Urdu pack');
    await pumpScreen(
      tester,
      packId: 'ur-pack',
      downloader: _CannedPageDownloader(
        db,
        items: const [(1, 'حديث')],
      ),
    );

    expect(find.text('UR'), findsOneWidget);
  });

  testWidgets('rows survive textScaler 2.0 without overflowing',
      (tester) async {
    await seedPack();
    await pumpScreen(
      tester,
      textScale: 2,
      downloader: _CannedPageDownloader(
        db,
        items: const [
          (1, 'حديث طويل بعض الشيء لاختبار التفاف النص عند تكبير الخط'),
          (12, 'حديث آخر'),
        ],
        hasMore: true,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('١٢'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);

    // The numeral badge is a fixed 28 dp box: at 2.0 the text scales down
    // inside it instead of growing past the circle.
    final badge = tester.getSize(find.byType(FittedBox).first);
    expect(badge.width, lessThanOrEqualTo(28));
    expect(badge.height, lessThanOrEqualTo(28));
  });
}
