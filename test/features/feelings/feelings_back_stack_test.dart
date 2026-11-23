// Regression test for the Q43 → Q44 → Q45 "Next verse" back stack. It drives
// the REAL production screens (FeelingsScreen / Q43, FeelingVersesScreen /
// Q44, VerseDetailScreen / Q45) inside a REAL GoRouter whose paths match
// lib/app/routes/feelings_routes.dart — no mock Navigator and no stub button.
// Q43 is the chain entry and the third Back lands on it (not a stub shell).
import 'dart:async' show unawaited;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/feelings/data/feelings_repository.dart';
import 'package:quran_yahdi/features/feelings/domain/feeling.dart';
import 'package:quran_yahdi/features/feelings/presentation/feeling_verses_screen.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_cubit.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_screen.dart';
import 'package:quran_yahdi/features/feelings/presentation/verse_detail_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import '../../support/host.dart';

class _StubUthmani implements UthmaniTextSource {
  @override
  Future<Map<int, String>> forSurah(int surahId) async => {};
}

class _FakeRepo extends FeelingsRepository {
  _FakeRepo(AppDatabase db) : super(db, _StubUthmani(), AyahRepository(db));

  @override
  Future<FeelingVerseView> load(FeelingKey feeling, FeelingVerse verse) async {
    return FeelingVerseView(
      feeling: feeling,
      verse: verse,
      fullText: verse.excerpt,
      surahName: verse.surah == 13 ? 'الرعد' : 'الطلاق',
      surahNameEn: verse.surah == 13 ? 'The Thunder' : 'Divorce',
      juz: 13,
      ayahId: verse.surah * 100 + verse.ayah,
    );
  }

  @override
  Future<bool> isSaved(int ayahId) async => false;
}

Future<void> _pumpRounds(WidgetTester tester, {int rounds = 40}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late GoRouter router;
  late AppDatabase db;
  late FeelingsCubit feelingsCubit;
  late FeelingVersesCubit versesCubit;
  late VerseDetailCubit arRadCubit;
  late VerseDetailCubit atTalaqCubit;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    final repo = _FakeRepo(db);
    feelingsCubit = FeelingsCubit(repo);
    versesCubit = FeelingVersesCubit(repo, FeelingKey.qalaq);
    arRadCubit = VerseDetailCubit(repo, FeelingKey.qalaq, 13, 28);
    atTalaqCubit = VerseDetailCubit(repo, FeelingKey.qalaq, 65, 2);
    await feelingsCubit.start();
    await versesCubit.start();
    await arRadCubit.start();
    await atTalaqCubit.start();

    router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        ShellRoute(
          builder: (_, _, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const Scaffold(body: Text('HOME-SHELL')),
            ),
          ],
        ),
        // Q43 — the real feelings picker (chain entry).
        GoRoute(
          path: AppRoutes.feelings,
          builder: (_, _) => BlocProvider<FeelingsCubit>.value(
            value: feelingsCubit,
            child: const FeelingsScreen(),
          ),
        ),
        // Q44 — the real two-verse list.
        GoRoute(
          path: AppRoutes.feelingsVerses,
          builder: (_, _) => BlocProvider<FeelingVersesCubit>.value(
            value: versesCubit,
            child: const FeelingVersesScreen(),
          ),
        ),
        // Q45 — the real verse detail, which owns the Next-verse button.
        GoRoute(
          path: AppRoutes.feelingsVerse,
          builder: (_, state) {
            final ayah = state.uri.queryParameters['ayah'];
            final cubit = ayah == '28' ? arRadCubit : atTalaqCubit;
            return BlocProvider<VerseDetailCubit>.value(
              value: cubit,
              child: const VerseDetailScreen(),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(feelingsCubit.close);
    addTearDown(versesCubit.close);
    addTearDown(arRadCubit.close);
    addTearDown(atTalaqCubit.close);
    addTearDown(db.close);
  });

  testWidgets(
    'Q43 → Q44 → Ar-Ra\'d 28 → At-Talaq 2; three pops land back on Q43',
    (tester) async {
      await tester.pumpWidget(routedAppShell(router: router));
      await _pumpRounds(tester);
      expect(router.state.uri.path, AppRoutes.home);

      // Q43 — push the real feelings picker from Home.
      unawaited(router.push(AppRoutes.feelings));
      await _pumpRounds(tester);
      expect(router.state.uri.path, AppRoutes.feelings);
      expect(find.text('شعورك إيه دلوقتي؟'), findsOneWidget);

      // Q43 → Q44: tap the "قلق" (anxiety) tile (scroll it into view first).
      final qalaqTile = find.text('قلق');
      await tester.ensureVisible(qalaqTile);
      await _pumpRounds(tester);
      await tester.tap(qalaqTile);
      await _pumpRounds(tester);
      expect(router.state.uri.path, AppRoutes.feelingsVerses);

      // Q44 → first Q45 verse: Ar-Ra'd 28.
      await tester.tap(find.text('اقرأ وتدبر').first);
      await _pumpRounds(tester);
      expect(router.state.uri.toString(), contains('surah=13'));
      expect(router.state.uri.toString(), contains('ayah=28'));

      // Next verse pushes At-Talaq 2 (must not reset the stack).
      await tester.tap(find.text('الآية التالية'));
      await _pumpRounds(tester);
      expect(router.state.uri.toString(), contains('surah=65'));
      expect(router.state.uri.toString(), contains('ayah=2'));

      // Back 1 → Ar-Ra'd 28.
      router.pop();
      await _pumpRounds(tester);
      expect(router.state.uri.toString(), contains('surah=13'));
      expect(router.state.uri.toString(), contains('ayah=28'));

      // Back 2 → Q44.
      router.pop();
      await _pumpRounds(tester);
      expect(router.state.uri.path, AppRoutes.feelingsVerses);

      // Back 3 → Q43 (the chain entry, not a stub and not app exit).
      router.pop();
      await _pumpRounds(tester);
      expect(router.state.uri.path, AppRoutes.feelings);
      expect(find.text('شعورك إيه دلوقتي؟'), findsOneWidget);
    },
  );
}
