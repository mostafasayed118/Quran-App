import 'package:flutter/foundation.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../domain/prayer_skin.dart';

/// Holds the prayer-skin choice and notifies the app root.
///
/// Same contract as `AppThemeController`: the switch is applied immediately
/// (notify first, persist second), and a failed write only costs the choice on
/// the next launch — logged, never surfaced, never blocking. A failed read
/// keeps [PrayerSkinMode.fixed], so a degraded boot ships the known theme.
class PrayerSkinController extends ChangeNotifier {
  /// Creates the controller over its storage; [load] performs the first read.
  PrayerSkinController(this._source);

  final PrayerSkinSource _source;
  PrayerSkinMode _mode = PrayerSkinMode.fixed;
  bool _loaded = false;

  /// The selected mode.
  PrayerSkinMode get mode => _mode;

  /// Whether the chrome should follow the prayer period.
  bool get followsPrayer => _mode == PrayerSkinMode.follow;

  /// Whether the stored preference was read (tests / first-frame checks).
  bool get loaded => _loaded;

  /// Reads the stored mode; a failure keeps [PrayerSkinMode.fixed].
  Future<void> load() async {
    try {
      _mode = await _source.load();
    } on Object catch (error, stackTrace) {
      appLog(
        'prayer skin read failed',
        name: 'quran_yahdi/theme',
        error: error,
        stackTrace: stackTrace,
      );
      _mode = PrayerSkinMode.fixed;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Switches the skin and persists it.
  Future<void> setMode(PrayerSkinMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _source.save(mode);
    } on Object catch (error, stackTrace) {
      appLog(
        'prayer skin write failed',
        name: 'quran_yahdi/theme',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
