import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/settings_store.dart';

/// The plan the OS already holds: its fingerprint plus the exact-alarm mode
/// it was written with (the mode is part of "already applied").
class ReminderPlanSnapshot {
  /// Creates the snapshot for [fingerprint] and [exact].
  const ReminderPlanSnapshot({required this.fingerprint, required this.exact});

  /// The deterministic plan fingerprint.
  final String fingerprint;

  /// Whether the alarms were written with exact scheduling.
  final bool exact;
}

/// Persists [ReminderPlanSnapshot] so a new process (or the background
/// isolate) can skip a plan that is already on the OS.
abstract interface class ReminderPlanStore {
  /// The last applied plan, or null when none was recorded.
  Future<ReminderPlanSnapshot?> read();

  /// Records [snapshot] after a successful apply.
  Future<void> write(ReminderPlanSnapshot snapshot);

  /// Drops the record (used when a targeted cancel invalidates it).
  Future<void> clear();
}

/// Stores the snapshot as one JSON row in the settings table.
///
/// Device-local scheduling state, not user data: it is deliberately absent
/// from the backup settings whitelist.
class DriftReminderPlanStore implements ReminderPlanStore {
  /// Creates the store over [db].
  DriftReminderPlanStore(this._db);

  /// The settings key that owns the snapshot.
  static const String key = 'reminder_plan_v1';

  final AppDatabase _db;

  late final SettingsStore _settings = SettingsStore(_db);

  @override
  Future<ReminderPlanSnapshot?> read() async {
    final raw = await _settings.read(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final fingerprint = decoded['fingerprint'];
      final exact = decoded['exact'];
      if (fingerprint is! String || exact is! bool) return null;
      return ReminderPlanSnapshot(fingerprint: fingerprint, exact: exact);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(ReminderPlanSnapshot snapshot) => _settings.write(
        key,
        jsonEncode({
          'fingerprint': snapshot.fingerprint,
          'exact': snapshot.exact,
        }),
      );

  @override
  Future<void> clear() => _settings.remove(key);
}
