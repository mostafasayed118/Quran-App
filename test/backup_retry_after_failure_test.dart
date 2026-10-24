import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_state.dart';

import 'support/test_db.dart';

class FlakyBackupService extends BackupService {
  FlakyBackupService(AppDatabase db) : super(db: db, reschedule: () async {});

  int exportCalls = 0;
  bool failNext = true;

  @override
  Future<String> exportJson() async {
    exportCalls++;
    if (failNext) {
      failNext = false;
      throw StateError('export failed');
    }
    return '{}';
  }
}

void main() {
  test('export retries from the failed state without an explicit acknowledge',
      () async {
    final db = newTestDb();
    final service = FlakyBackupService(db);
    final cubit = BackupCubit(service: service, shareJson: (_) async {});

    await cubit.export();
    expect(cubit.state, isA<BackupFailed>());
    expect((cubit.state as BackupFailed).duringExport, isTrue);
    expect(service.exportCalls, 1);

    await cubit.export();
    expect(cubit.state, isA<BackupExported>());
    expect(service.exportCalls, 2);

    await cubit.close();
  });
}
