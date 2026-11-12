part of 'player_sheet.dart';

class _SeekRow extends StatelessWidget {
  const _SeekRow({
    required this.value,
    required this.maxMs,
    required this.positionLabel,
    required this.durationLabel,
    required this.colors,
    this.onChanged,
    this.onChangeEnd,
  });

  final double value;
  final double maxMs;
  final String positionLabel;
  final String durationLabel;
  final ColorScheme colors;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          value: value,
          max: maxMs > 0 ? maxMs : 1,
          label: positionLabel,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                positionLabel,
                style: AppTheme.mutedAt(colors, 12),
              ),
              Text(
                durationLabel,
                style: AppTheme.mutedAt(colors, 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Repeat / speed / sleep-timer row.
///
/// Lifted out of a 189-line `build()`; it takes plain values and one callback
/// so it holds no state of its own.
class _OptionsRow extends StatelessWidget {
  const _OptionsRow({
    required this.loc,
    required this.cubit,
    required this.speed,
    required this.repeatMode,
    required this.sleepTimer,
    required this.onSleepPressed,
  });

  final AppLocalizations loc;
  final PlaybackCubit cubit;
  final double speed;
  final PlaybackRepeatMode repeatMode;
  final Duration? sleepTimer;
  final VoidCallback onSleepPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        IconButton(
          tooltip: loc.repeatSurah,
          isSelected: repeatMode == PlaybackRepeatMode.one,
          icon: const Icon(Icons.repeat_one),
          onPressed: cubit.toggleRepeat,
        ),
        Tooltip(
          message: loc.playbackSpeed,
          child: ActionChip(
            onPressed: cubit.cycleSpeed,
            label: Text(loc.digits(_speedLabel(speed))),
          ),
        ),
        TextButton.icon(
          onPressed: onSleepPressed,
          icon: Icon(
            sleepTimer == null ? Icons.bedtime_outlined : Icons.bedtime,
          ),
          label: Text(
            sleepTimer == null
                ? loc.sleepTimer
                : loc.sleepTimerMinutes(loc.number(sleepTimer!.inMinutes)),
          ),
        ),
      ],
    );
  }
}

/// Previous / play-pause / next / stop.
class _TransportRow extends StatelessWidget {
  const _TransportRow({
    required this.loc,
    required this.cubit,
    required this.track,
  });

  final AppLocalizations loc;
  final PlaybackCubit cubit;
  final _Track track;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: loc.previousSurah,
          onPressed: cubit.hasPreviousSurah ? cubit.previousSurah : null,
          icon: const Icon(Icons.skip_previous),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
          iconSize: 34,
          tooltip: track.playing ? loc.pauseTooltip : loc.playTooltip,
          icon: Icon(track.playing ? Icons.pause : Icons.play_arrow),
          onPressed: cubit.toggle,
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: loc.nextSurah,
          onPressed: cubit.hasNextSurah ? cubit.nextSurah : null,
          icon: const Icon(Icons.skip_next),
        ),
        const SizedBox(width: AppSpacing.lg),
        IconButton(
          tooltip: loc.stopTooltip,
          icon: const Icon(Icons.stop),
          // The state-driven branch above closes the sheet once the cubit
          // reaches its initial state; popping here as well could close the
          // underlying route on a double pop.
          onPressed: cubit.stopAndReset,
        ),
      ],
    );
  }
}
