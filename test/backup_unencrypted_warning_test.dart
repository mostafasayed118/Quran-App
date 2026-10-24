import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_section.dart';

import 'support/host.dart';
import 'support/test_db.dart';

/// The export row must carry an explicit in-app warning: the backup file is
/// plain JSON (the v1.0 risk-mitigation decision, see
/// docs/superpowers/specs/2026-10-24-backup-encryption-decision.md).
void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  Future<void> pumpSection(WidgetTester tester,
      {Locale locale = const Locale('ar')}) async {
    final cubit = BackupCubit(
      service: BackupService(db: db, reschedule: () async {}),
      pickBytes: () async => null,
      shareJson: (_) async {},
    );
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      locale: locale,
      wrap: (app) => BlocProvider<BackupCubit>.value(value: cubit, child: app),
      home: const Scaffold(body: BackupSection()),
      settle: false,
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('the Arabic export row warns that the file is unencrypted',
      (tester) async {
    await pumpSection(tester);

    expect(find.textContaining('غير مشفَّر'), findsOneWidget);
    expect(find.textContaining('احفظه في مكان آمن'), findsOneWidget);
  });

  testWidgets('the English export row shows the English warning',
      (tester) async {
    await pumpSection(tester, locale: const Locale('en'));

    expect(find.textContaining("isn't encrypted"), findsOneWidget);
    expect(find.textContaining('Keep it somewhere safe'), findsOneWidget);
  });
}
