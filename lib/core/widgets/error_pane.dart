import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'async_view.dart';

/// Renders the localized generic error pane shared by every failed-load arm.
/// Failures are logged at their emission site (the cubit), never during build.
Widget errorPane(AppLocalizations loc) => ErrorView(loc.genericError);
