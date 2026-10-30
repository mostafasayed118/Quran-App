import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_state.dart';

import 'support/test_db.dart';

/// Returns an encoded document larger than the import cap without touching
/// the database; the cubit must refuse to share it.
class _OversizedService extends BackupService {
  _OversizedService({required super.db}) : super(reschedule: () async {});

  @override
  Future<String> exportJson() async =>
      List.filled(kBackupMaxBytes + 1, 'x').join();
}

void main() {
  test('export refuses a payload larger than the import cap', () async {
    final db = newTestDb();
    addTearDown(db.close);
    var shared = 0;
    final cubit = BackupCubit(
      service: _OversizedService(db: db),
      shareJson: (_) async => shared++,
    );
    addTearDown(cubit.close);

    await cubit.export();

    expect(shared, 0);
    expect(cubit.state, isA<BackupFailed>());
    expect((cubit.state as BackupFailed).duringExport, isTrue);
  });

  test('a within-cap payload is still shared', () async {
    final db = newTestDb();
    addTearDown(db.close);
    var shared = 0;
    final cubit = BackupCubit(
      service: BackupService(db: db, reschedule: () async {}),
      shareJson: (_) async => shared++,
    );
    addTearDown(cubit.close);

    await cubit.export();

    expect(shared, 1);
    expect(cubit.state, isA<BackupExported>());
  });
}
