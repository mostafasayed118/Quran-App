import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_io.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_state.dart';

import 'support/test_db.dart';

/// [bytes] ASCII bytes: `x` is one byte in UTF-8, so the string length IS the
/// encoded size and the cap boundary is exact.
String _ascii(int bytes) => List.filled(bytes, 'x').join();

/// Counts size checks and can return a chosen envelope from the encrypt step,
/// so both export paths can be driven without running Argon2id.
class _CountingService extends BackupService {
  _CountingService({required super.db, this.encrypted})
    : super(reschedule: () async {});

  final String? encrypted;
  int checks = 0;

  @override
  Future<bool> exceedsLimit(String text) {
    checks++;
    return super.exceedsLimit(text);
  }

  @override
  Future<String> encryptForExport(String json, String passphrase) async =>
      encrypted ?? super.encryptForExport(json, passphrase);
}

void main() {
  test(
    'the worker-isolate measure completes and pins the cap boundary',
    () async {
      // The real Isolate.run entrypoint, not the inline flutter-test escape:
      // this is the path production takes.
      expect(
        await exceedsBackupLimitInIsolate(_ascii(kBackupMaxBytes - 1)),
        isFalse,
      );
      expect(
        await exceedsBackupLimitInIsolate(_ascii(kBackupMaxBytes)),
        isFalse,
      );
      expect(
        await exceedsBackupLimitInIsolate(_ascii(kBackupMaxBytes + 1)),
        isTrue,
      );
    },
  );

  test(
    'the service measure accepts the exact cap and rejects one byte over',
    () async {
      final db = newTestDb();
      addTearDown(db.close);
      final service = BackupService(db: db, reschedule: () async {});

      expect(await service.exceedsLimit(_ascii(kBackupMaxBytes - 1)), isFalse);
      expect(await service.exceedsLimit(_ascii(kBackupMaxBytes)), isFalse);
      expect(await service.exceedsLimit(_ascii(kBackupMaxBytes + 1)), isTrue);
    },
  );

  test('the plain export path checks the size once before sharing', () async {
    final db = newTestDb();
    addTearDown(db.close);
    final service = _CountingService(db: db);
    var shared = 0;
    final cubit = BackupCubit(
      service: service,
      shareJson: (_) async => shared++,
    );
    addTearDown(cubit.close);

    await cubit.export();

    expect(service.checks, 1);
    expect(shared, 1);
    expect(cubit.state, isA<BackupExported>());
  });

  test('the encrypted export path refuses an over-cap envelope', () async {
    final db = newTestDb();
    addTearDown(db.close);
    final service = _CountingService(
      db: db,
      encrypted: _ascii(kBackupMaxBytes + 1),
    );
    var shared = 0;
    final cubit = BackupCubit(
      service: service,
      shareJson: (_) async => shared++,
    );
    addTearDown(cubit.close);

    await cubit.exportEncrypted('correct horse battery staple');

    expect(service.checks, 1);
    expect(shared, 0);
    expect(cubit.state, isA<BackupFailed>());
    expect((cubit.state as BackupFailed).duringExport, isTrue);
  });

  test('the encrypted export path shares a within-cap envelope', () async {
    final db = newTestDb();
    addTearDown(db.close);
    final service = _CountingService(db: db, encrypted: '{"app":"envelope"}');
    var shared = 0;
    final cubit = BackupCubit(
      service: service,
      shareJson: (_) async => shared++,
    );
    addTearDown(cubit.close);

    await cubit.exportEncrypted('correct horse battery staple');

    expect(service.checks, 1);
    expect(shared, 1);
    expect(cubit.state, isA<BackupExported>());
  });
}
