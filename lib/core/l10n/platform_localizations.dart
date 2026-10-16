import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Localized strings for surfaces OUTSIDE the widget tree (notification
/// channel name, media metadata). The app is AR-pinned (see `app.dart`), so
/// this resolves that same pinned locale — when the W7c locale un-pin lands,
/// this is the single place to switch every outside-the-tree surface.
AppLocalizations platformLocalizations() =>
    lookupAppLocalizations(const Locale('ar'));
