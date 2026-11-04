import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../domain/app_locale.dart';

/// The language used by surfaces OUTSIDE the widget tree: notification titles
/// (composed when the alarm is scheduled), the Android channel name and the
/// media metadata.
///
/// The tree itself follows `MaterialApp.locale`; this is the matching seam for
/// the surfaces that have no `BuildContext`. `AppLocaleController` publishes
/// every change here, so a replan after a language switch composes the copy in
/// the language the user is reading.
///
/// Disclosed limitation: a notification is localized at SCHEDULE time (fire
/// time may happen with the app dead), so an alarm scheduled before a language
/// switch keeps its old copy until the next replan.
AppLanguage _platformLanguage = AppLanguage.arabic;

/// The language the platform surfaces compose their copy in.
@visibleForTesting
AppLanguage get platformLanguage => _platformLanguage;

/// Publishes the current language (called by the locale controller).
set platformLanguage(AppLanguage language) => _platformLanguage = language;

/// Localized strings for surfaces outside the widget tree.
AppLocalizations platformLocalizations() =>
    lookupAppLocalizations(Locale(_platformLanguage.code));
