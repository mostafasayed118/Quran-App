import '../../../core/db/app_database.dart';
import '../../../core/domain/onboarding_status.dart';

/// Stores the first-run flag in the local settings table.
class OnboardingRepository implements OnboardingStatusSource {
  /// Creates the repository over the app database.
  OnboardingRepository(this._db);

  /// Settings key; deliberately outside the backup whitelist (a restore onto
  /// a fresh install should still show the setup card).
  static const completedKey = 'onboarding_completed';

  final AppDatabase _db;

  @override
  Future<bool> isCompleted() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((setting) => setting.key.equals(completedKey)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  @override
  Future<void> markCompleted() async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: completedKey,
            value: 'true',
          ),
        );
  }
}
