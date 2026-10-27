import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_section.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_state.dart';

import 'support/host.dart';
import 'support/test_db.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

BackupDocument _doc() => BackupDocument(
      exportedAt: DateTime(2026, 10, 19),
      schemaVersion: 2,
      data: const BackupData(
        bookmarks: [],
        lastReadAyahId: null,
        khatma: [],
        prayerLog: [],
        tasbih: null,
        settings: {},
      ),
    );

void main() {
  late BackupService service;

  setUp(() {
    service = BackupService(db: newTestDb(), reschedule: () async {});
  });

  BackupCubit newCubit({BackupPickBytes? pickBytes}) => BackupCubit(
        service: service,
        pickBytes: pickBytes ?? () async => null,
        shareJson: (_) async {},
      );

  test('cancelPreview and acknowledge are no-ops after close', () async {
    final cubit = newCubit(
      pickBytes: () async => utf8.encode(encode(_doc())),
    );
    await cubit.importFromFile();
    expect(cubit.state, isA<BackupPreviewReady>());
    await cubit.close();

    expect(cubit.cancelPreview, returnsNormally);
    expect(cubit.acknowledge, returnsNormally);
  });

  test('export completes after close', () async {
    final cubit = newCubit();
    await cubit.close();

    await expectLater(cubit.export(), completes);
  });

  test('importFromFile completes after close', () async {
    final cubit = newCubit();
    await cubit.close();

    await expectLater(cubit.importFromFile(), completes);
  });

  test('confirmImport completes after close with a pending preview', () async {
    final cubit = newCubit(
      pickBytes: () async => utf8.encode(encode(_doc())),
    );
    await cubit.importFromFile();
    expect(cubit.state, isA<BackupPreviewReady>());
    await cubit.close();

    await expectLater(cubit.confirmImport(), completes);
  });

  testWidgets('system back dismisses the preview and restores idle',
      (tester) async {
    final cubit = newCubit(
      pickBytes: () async => utf8.encode(encode(_doc())),
    );
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<BackupCubit>.value(value: cubit, child: app),
      home: const Scaffold(body: BackupSection()),
      settle: false,
    );
    await _settle(tester);

    await tester.tap(find.text('استيراد البيانات'));
    await _settle(tester);
    expect(find.text('مراجعة الاستيراد'), findsOneWidget);
    expect(cubit.state, isA<BackupPreviewReady>());

    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(find.text('مراجعة الاستيراد'), findsNothing);
    expect(cubit.state, isA<BackupIdle>());
  });
}
