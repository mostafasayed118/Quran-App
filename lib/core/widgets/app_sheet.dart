import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';

/// The app's one modal-sheet entry point.
///
/// It keeps every sheet on the same M3 measure: capped at
/// [AppBreakpoints.sheetMaxWidth] and centred on tablets, a drag handle, and
/// the top/side safe area respected. Callers that need the sheet to survive a
/// short landscape viewport pass [isScrollControlled] and make their own
/// content scrollable.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: AppBreakpoints.sheetMaxWidth),
    builder: builder,
  );
}
