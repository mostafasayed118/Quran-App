import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';
import '../../../core/domain/onboarding_status.dart';

/// Stores the first-run flag in the local settings table.
class OnboardingRepository implements OnboardingStatusSource {
  /// Creates the repository over the app database.
  OnboardingRepository(this._db);

  /// Settings key; deliberately outside the backup whitelist (a restore onto
  /// a fresh install should still show the setup card).
  static const completedKey = 'onboarding_completed';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<bool> isCompleted() async =>
      (await _settings.read(completedKey)) == 'true';

  @override
  Future<void> markCompleted() => _settings.write(completedKey, 'true');
}
