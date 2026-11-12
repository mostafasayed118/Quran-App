part of 'player_sheet.dart';

String _speedLabel(double speed) {
  final text =
      speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : '$speed';
  return '$text×';
}

Future<void> _showSleepMenu(
  BuildContext context,
  PlaybackCubit cubit,
  Duration? current,
) {
  final loc = AppLocalizations.of(context);
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: EdgeInsets.only(bottom: appBottomInset(sheetContext)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              loc.sleepTimer,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final minutes in const [15, 30, 45, 60])
            ListTile(
              title: Text(loc.sleepTimerMinutes(loc.number(minutes))),
              trailing: current?.inMinutes == minutes
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                cubit.startSleepTimer(Duration(minutes: minutes));
              },
            ),
          ListTile(
            title: Text(loc.sleepTimerOff),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.of(sheetContext).pop();
              cubit.cancelSleepTimer();
            },
          ),
        ],
      ),
    ),
  );
}
