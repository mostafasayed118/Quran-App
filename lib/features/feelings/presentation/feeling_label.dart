import 'package:quran_yahdi/l10n/app_localizations.dart';

/// The localized display name for a feeling key.
///
/// One source for the eight catalog keys. The three feelings screens used to
/// carry identical copies of this switch; call this instead.
String feelingLabel(AppLocalizations loc, String key) => switch (key) {
  'qalaq' => loc.feelingQalaq,
  'huzn' => loc.feelingHuzn,
  'wahda' => loc.feelingWahda,
  'hayra' => loc.feelingHayra,
  'khawf' => loc.feelingKhawf,
  'ghadab' => loc.feelingGhadab,
  'imtinam' => loc.feelingImtinam,
  _ => loc.feelingAmal,
};
