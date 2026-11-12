part of 'backup_service.dart';

class _ApplyPlan {
  const _ApplyPlan({
    required this.bookmarks,
    required this.lastRead,
    required this.khatma,
    required this.prayerLog,
    required this.tasbih,
    required this.settings,
    required this.khatmaRowId,
  });

  final BookmarkMerge bookmarks;
  final LastReadMerge lastRead;
  final KhatmaMerge khatma;
  final PrayerLogMerge prayerLog;
  final TasbihMerge tasbih;
  final SettingsMerge settings;

  /// Row id of the existing single khatma row (update-in-place target).
  final int? khatmaRowId;

  BackupSummary get summary => BackupSummary(
        newBookmarks: bookmarks.newCount,
        mergedPrayerDays: prayerLog.mergedDays,
        planReplaced: khatma.replaced,
        tasbihCountDelta: tasbih.countDelta,
        tasbihChanged: tasbih.changed,
        lastReadChanged: lastRead.changed,
        settingsKeysApplied: settings.appliedCount,
        rejectedEntries: bookmarks.rejected + khatma.rejected,
      );

  bool get reminderRelevantChanged =>
      settings.toWrite.keys.any(kBackupReminderRelevantKeys.contains);
}
