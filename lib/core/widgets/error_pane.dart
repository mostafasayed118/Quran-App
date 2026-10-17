import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'async_view.dart';

/// Logs [message] under `quran_yahdi/<source>` and renders the localized
/// generic error pane. Shared by every screen that maps a failed load
/// (previously copy-pasted in 8 screens).
Widget errorPane(AppLocalizations loc, String message, String source) {
  dev.log(message, name: 'quran_yahdi/$source');
  return ErrorView(loc.genericError);
}
