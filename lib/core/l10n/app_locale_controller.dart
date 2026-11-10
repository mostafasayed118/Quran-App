import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../domain/app_locale.dart';
import 'platform_localizations.dart';

/// The locales the app advertises to the OS and to `MaterialApp`.
///
/// Arabic first: it stays the default for a fresh install (D1, now a runtime
/// switch rather than a hard pin).
const List<Locale> kSupportedLocales = <Locale>[Locale('ar'), Locale('en')];

/// Holds the user's language and notifies the app root when it changes.
///
/// The app root rebuilds `MaterialApp` from [locale]; the switch is applied
/// immediately (notify first, persist second) so the tap never waits on a
/// database write. A failed write only costs the choice on the next launch —
/// it is logged, never surfaced, and never blocks the switch.
class AppLocaleController extends ChangeNotifier {
  /// Creates the controller over its storage; [load] performs the first read.
  AppLocaleController(this._source);

  final AppLocaleSource _source;
  AppLanguage _language = AppLanguage.arabic;
  bool _loaded = false;

  /// The selected language.
  AppLanguage get language => _language;

  /// The selected language as a Flutter [Locale].
  Locale get locale => Locale(_language.code);

  /// Whether the stored preference was read (tests / first-frame checks).
  bool get loaded => _loaded;

  /// Reads the stored language; a failure keeps Arabic.
  Future<void> load() async {
    try {
      _language = await _source.load();
    } on Object catch (error, stackTrace) {
      appLog('app locale read failed',
          name: 'quran_yahdi/locale', error: error, stackTrace: stackTrace);
      _language = AppLanguage.arabic;
    }
    _loaded = true;
    _publish();
    notifyListeners();
  }

  /// Switches the language and persists it.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    _publish();
    notifyListeners();
    try {
      await _source.save(language);
    } on Object catch (error, stackTrace) {
      appLog('app locale write failed',
          name: 'quran_yahdi/locale', error: error, stackTrace: stackTrace);
    }
  }

  /// Keeps the outside-the-tree surfaces (notification copy, channel name) in
  /// step with the widget tree.
  void _publish() => platformLanguage = _language;
}
