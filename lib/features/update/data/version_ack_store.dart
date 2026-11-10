import 'package:in_app_review/in_app_review.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../core/db/app_database.dart';
import '../../../core/domain/store_listing.dart';
import '../../../core/domain/version_ack_store.dart';

/// Settings-table key for the "dismissed the optional update prompt for build
/// X" marker. Not part of the backup whitelist (restoring must not resurrect
/// a dismissed recommendation for a version the user has since installed).
const String versionUpdatePromptAckKey = 'version_update_prompt_ack';

/// Settings-backed ack store for the recommended-update prompt.
class DriftVersionAckStore implements VersionAckStore {
  DriftVersionAckStore(this._db);

  final AppDatabase _db;

  @override
  Future<String?> read() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(versionUpdatePromptAckKey)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> write(String latest) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: versionUpdatePromptAckKey,
            value: latest,
          ),
        );
  }
}

/// The store id used in the public Play listing.
const String kPlayStoreId = 'com.mostafasayed.quranyahdi';

/// Production gateway: asks the Play surface to open the listing. On a
/// sideloaded build the market intent may silently do nothing; the caller
/// surfaces that as a toast so the button never dead-ends.
class InAppReviewStoreListing implements StoreListingGateway {
  @override
  Future<bool> open() async {
    try {
      await InAppReview.instance.openStoreListing(appStoreId: kPlayStoreId);
      return true;
    } on Object catch (error, stackTrace) {
      appLog(
        'store listing open failed',
        name: 'quran_yahdi/version-gate',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
