import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_route_scope.dart';

import 'support/test_db.dart';

class _CountingReaderCubit extends ReaderCubit {
  _CountingReaderCubit({
    required super.ayahRepository,
    required super.lastReadRepository,
    required int surah,
    required this.onStart,
    required this.onClose,
  }) : super(surahId: surah, initialAyah: 0);

  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Future<void> start() async {
    // The scope contract is the lifecycle, not the reader load: counting here
    // keeps the test free of the real stream/DB work.
    onStart();
  }

  @override
  Future<void> close() {
    onClose();
    return super.close();
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('a new identity creates and starts one cubit and closes the old',
      (tester) async {
    var created = 0;
    var started = 0;
    var closed = 0;

    Widget host(int surah) {
      return MaterialApp(
        home: Scaffold(
          body: ReaderRouteScope(
            surah: surah,
            ayah: 0,
            create: () {
              created++;
              return _CountingReaderCubit(
                ayahRepository: AyahRepository(db),
                lastReadRepository: LastReadRepository(db),
                surah: surah,
                onStart: () => started++,
                onClose: () => closed++,
              );
            },
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    await tester.pumpWidget(host(1));
    await tester.pump();
    expect(created, 1);
    expect(started, 1);
    expect(closed, 0);

    await tester.pumpWidget(host(2));
    await tester.pump();

    expect(created, 2);
    expect(started, 2);
    expect(closed, 1);
  });
}
