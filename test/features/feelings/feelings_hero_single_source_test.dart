// Issue 3 (audit Top 5): the Q43 hero verse is one product fact. The rendered
// reference, excerpt and tadabbur section must stay exactly what users saw,
// while the widgets read them from the single catalog source.
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/feelings/data/feelings_repository.dart';
import 'package:quran_yahdi/features/feelings/domain/feeling.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_cubit.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_screen.dart';
import 'package:quran_yahdi/features/feelings/presentation/verse_detail_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import '../../support/host.dart';
import '../../support/test_db.dart';

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

void main() {
  late AppDatabase db;
  late FeelingsCubit heroCubit;
  late VerseDetailCubit arRadCubit;
  late VerseDetailCubit atTalaqCubit;

  setUp(() async {
    db = newTestDb();
    final repo = _FakeRepo(db);
    heroCubit = FeelingsCubit(repo);
    arRadCubit = VerseDetailCubit(repo, FeelingKey.qalaq, 13, 28);
    atTalaqCubit = VerseDetailCubit(repo, FeelingKey.qalaq, 65, 2);
    await heroCubit.start();
    await arRadCubit.start();
    await atTalaqCubit.start();
    addTearDown(heroCubit.close);
    addTearDown(arRadCubit.close);
    addTearDown(atTalaqCubit.close);
  });

  test('the catalog is the one source of the hero identity', () {
    expect(FeelingsCatalog.heroVerse.reference, '13:28');
    expect(FeelingsCatalog.heroReference, '13:28');
    expect(FeelingsCatalog.heroExcerpt, FeelingsCatalog.heroVerse.excerpt);
    expect(FeelingsCatalog.heroVerse.hasTadabbur, isTrue);
    for (final feeling in FeelingsCatalog.ordered) {
      for (final verse in feeling.verses) {
        if (verse.surah == 13 && verse.ayah == 28) continue;
        expect(
          verse.hasTadabbur,
          isFalse,
          reason: 'unexpected tadabbur on ${verse.reference}',
        );
      }
    }
  });

  testWidgets('Q43 renders the same hero excerpt and reference', (
    tester,
  ) async {
    await pumpAppHost(
      tester,
      home: BlocProvider<FeelingsCubit>.value(
        value: heroCubit,
        child: const FeelingsScreen(),
      ),
    );

    expect(find.text(FeelingsCatalog.heroVerse.excerpt), findsOneWidget);
    expect(find.text('سورة الرعد، الآية 28'), findsOneWidget);
  });

  testWidgets('Q45 shows tadabbur only on the canonical hero verse', (
    tester,
  ) async {
    await pumpAppHost(
      tester,
      home: BlocProvider<VerseDetailCubit>.value(
        value: arRadCubit,
        child: const VerseDetailScreen(),
      ),
    );
    expect(find.text('سورة الرعد • الآية 28 • الجزء 13'), findsOneWidget);
    expect(find.text('تدبر الآية ولمسة السكينة'), findsOneWidget);
    expect(
      find.text(
        'الطمأنينة ليست في زوال الهم، بل في ذكر الله مع الهم، فكلما ضاق صدرك، فارجع إلى الذكر.',
      ),
      findsOneWidget,
    );

    await pumpAppHost(
      tester,
      home: BlocProvider<VerseDetailCubit>.value(
        value: atTalaqCubit,
        child: const VerseDetailScreen(),
      ),
    );
    expect(find.text('سورة الطلاق • الآية 2 • الجزء 13'), findsOneWidget);
    expect(find.text('تدبر الآية ولمسة السكينة'), findsNothing);
  });
}
