import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../domain/app_theme.dart';

/// Holds the user's appearance choice and notifies the app root.
///
/// Same contract as `AppLocaleController`: the switch is applied immediately
/// (notify first, persist second) so the tap never waits on a database write,
/// and a failed write only costs the choice on the next launch — logged, never
/// surfaced, never blocking.
class AppThemeController extends ChangeNotifier {
  /// Creates the controller over its storage; [load] performs the first read.
  AppThemeController(this._source);

  final AppThemeSource _source;
  AppThemeMode _mode = AppThemeMode.system;
  bool _loaded = false;

  /// The selected mode.
  AppThemeMode get mode => _mode;

  /// The selected mode as a Flutter [ThemeMode].
  ThemeMode get themeMode => switch (_mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  /// Whether the stored preference was read (tests / first-frame checks).
  bool get loaded => _loaded;

  /// Reads the stored mode; a failure keeps [AppThemeMode.system].
  Future<void> load() async {
    try {
      _mode = await _source.load();
    } on Object catch (error, stackTrace) {
      dev.log('app theme read failed',
          name: 'quran_yahdi/theme', error: error, stackTrace: stackTrace);
      _mode = AppThemeMode.system;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Switches the appearance and persists it.
  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _source.save(mode);
    } on Object catch (error, stackTrace) {
      dev.log('app theme write failed',
          name: 'quran_yahdi/theme', error: error, stackTrace: stackTrace);
    }
  }
}
