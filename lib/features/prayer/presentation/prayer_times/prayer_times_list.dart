part of 'prayer_times_screen.dart';

class _TimesList extends StatefulWidget {
  const _TimesList({required this.state, required this.city});

  final PrayerTimesReady state;
  final City city;

  @override
  State<_TimesList> createState() => _TimesListState();
}

class _TimesListState extends State<_TimesList> with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A screen can mount while the app is already backgrounded; the binding's
    // current state decides, not the fact that initState ran.
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) _startTicker();
  }

  void _startTicker() {
    if (_ticker != null) return;
    final cubit = context.read<PrayerTimesCubit>();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      cubit.refreshCountdown();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopTicker();
      case AppLifecycleState.resumed:
        _startTicker();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = widget.state;
    final entries = state.entries;
    return ListView(
      padding: appScrollPadding(
        context,
        const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _CityCard(city: widget.city),
        const SizedBox(height: AppSpacing.md),
        // One panel, hairline-separated rows: seven separate elevated cards
        // made the list look like seven independent facts and pushed the last
        // prayer off screen.
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                _PrayerRow(
                  entry: entries[i],
                  remaining: state.remaining,
                  loc: loc,
                  timezone: state.city?.timezone,
                ),
                if (i != entries.length - 1)
                  const Divider(height: 1, indent: 14, endIndent: 14),
              ],
            ],
          ),
        ),
        if (state.nextTomorrowName != null &&
            state.nextTomorrowTime != null) ...[
          const SizedBox(height: AppSpacing.md),
          _TomorrowNote(
            name: state.nextTomorrowName!,
            time: state.nextTomorrowTime!,
            remaining: state.nextTomorrowRemaining,
            timezone: state.city?.timezone,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ForbiddenWindowsSection(
          entries: entries,
          timezone: state.city?.timezone,
        ),
      ],
    );
  }
}

/// What comes after today's last prayer.
///
/// Without it the panel went silent after Isha while Home advertised
/// tomorrow's Fajr — two screens disagreeing about the same fact.
