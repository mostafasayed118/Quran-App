import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_section.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_state.dart';

import 'support/host.dart';
import 'support/test_db.dart';

const _tooShort = 'عبارة المرور قصيرة جدًا — استخدم ٨ أحرف على الأقل';

/// Bounded pumps: drift futures + dialog animations advance on explicit pumps
/// only (no pumpAndSettle on a live DB, per the wave brief).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Records the passphrase the dialog would hand to the cubit; the export
/// dialog is the only creation surface, so the recorded value is the proof.
class _SpyCubit extends BackupCubit {
  _SpyCubit({required super.service}) : super(shareJson: (_) async {});

  final List<String> passphrases = [];

  @override
  Future<void> exportEncrypted(String passphrase) async {
    passphrases.add(passphrase);
  }
}

void main() {
  late AppDatabase db;
  late _SpyCubit cubit;

  setUp(() {
    db = newTestDb();
    cubit = _SpyCubit(
      service: BackupService(db: db, reschedule: () async {}),
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<void> openExportDialog(WidgetTester tester) async {
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<BackupCubit>.value(value: cubit, child: app),
      home: const Scaffold(body: BackupSection()),
      settle: false,
    );
    await settle(tester);
    await tester.tap(find.text('تصدير مشفّر'));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  Future<void> submit(WidgetTester tester, String first, String second) async {
    await tester.enterText(find.byType(TextField).at(0), first);
    await tester.enterText(find.byType(TextField).at(1), second);
    await tester.tap(find.widgetWithText(FilledButton, 'استعادة'));
    await settle(tester);
  }

  testWidgets('a 7-character new passphrase is rejected with the localized '
      'message', (tester) async {
    await openExportDialog(tester);

    await submit(tester, 'short12', 'short12');

    expect(find.text(_tooShort), findsOneWidget);
    expect(cubit.passphrases, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('an 8-character new passphrase is accepted', (tester) async {
    await openExportDialog(tester);

    await submit(tester, '12345678', '12345678');

    expect(cubit.passphrases, ['12345678']);
    expect(find.text(_tooShort), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a mismatch still reports the mismatch after the length gate', (
    tester,
  ) async {
    await openExportDialog(tester);

    await submit(tester, '12345678', '12345679');

    expect(find.text('عبارتا المرور غير متطابقتين'), findsOneWidget);
    expect(cubit.passphrases, isEmpty);
  });

  test(
    'the cubit refuses a too-short passphrase for any other caller',
    () async {
      var shared = 0;
      final plain = BackupCubit(
        service: BackupService(db: db, reschedule: () async {}),
        shareJson: (_) async => shared++,
      );
      addTearDown(plain.close);

      await plain.exportEncrypted('1234567');

      expect(shared, 0);
      expect(plain.state, isA<BackupFailed>());
      expect((plain.state as BackupFailed).duringExport, isTrue);
    },
  );
}
