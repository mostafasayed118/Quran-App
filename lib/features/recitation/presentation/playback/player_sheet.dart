import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/quran_limits.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import 'playback_cubit.dart';
import 'playback_state.dart';

/// Whether the player sheet must rebuild for [current].
///
/// While the user drags the seek bar the on-screen position is local
/// (`_dragging`), so a 1 Hz position tick changes nothing visible — and
/// rebuilding the whole sheet per tick is exactly the cost this avoids. Any
/// other change (track, play/pause, duration, failure) rebuilds.
bool playerSheetShouldRebuild(
  PlaybackState previous,
  PlaybackState current, {
  required bool dragging,
}) {
  if (!dragging) return true;
  return switch ((previous, current)) {
    (final PlaybackPlaying a, final PlaybackPlaying b) =>
      a.copyWith(position: Duration.zero) !=
          b.copyWith(position: Duration.zero),
    (final PlaybackPaused a, final PlaybackPaused b) =>
      a.copyWith(position: Duration.zero) !=
          b.copyWith(position: Duration.zero),
    _ => true,
  };
}

/// Tracks a seek position while the thumb is held, otherwise mirrors the
/// stream.
class _Track {
  const _Track({
    required this.reciterName,
    required this.surahNumber,
    required this.surahLabel,
    required this.position,
    required this.duration,
    required this.playing,
  });

  final String reciterName;
  final int surahNumber;
  final String surahLabel;
  final Duration position;
  final Duration duration;
  final bool playing;
}

/// The full player: transport, a seek bar and the track's times.
///
/// Opened from the mini player. The sheet is mounted on the root navigator,
/// above the route that owns the player's provider, so the cubit is read here
/// (where the provider is visible) and re-provided inside the sheet.
Future<void> showPlayerSheet(BuildContext context) {
  final cubit = context.read<PlaybackCubit>();
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider<PlaybackCubit>.value(
      value: cubit,
      child: const _PlayerSheet(),
    ),
  );
}

class _PlayerSheet extends StatefulWidget {
  const _PlayerSheet();

  @override
  State<_PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<_PlayerSheet> {
  /// The dragged position in milliseconds; null when the thumb is released.
  double? _dragging;

  String _clock(Duration d) {
    final loc = AppLocalizations.of(context);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return loc.digits('${d.inHours}:$minutes:$seconds');
    }
    return loc.digits('${d.inMinutes}:$seconds');
  }

  _Track? _trackOf(BuildContext context, PlaybackState state) {
    final loc = AppLocalizations.of(context);
    return switch (state) {
      PlaybackPlaying(
        :final reciterName,
        :final surahNumber,
        :final surahName,
        :final position,
        :final duration,
      ) =>
        _Track(
          reciterName: reciterName,
          surahNumber: surahNumber,
          surahLabel: surahName.isEmpty
              ? loc.surahBadge(loc.number(surahNumber))
              : surahName,
          position: position,
          duration: duration,
          playing: true,
        ),
      PlaybackPaused(
        :final reciterName,
        :final surahNumber,
        :final surahName,
        :final position,
        :final duration,
      ) =>
        _Track(
          reciterName: reciterName,
          surahNumber: surahNumber,
          surahLabel: surahName.isEmpty
              ? loc.surahBadge(loc.number(surahNumber))
              : surahName,
          position: position,
          duration: duration,
          playing: false,
        ),
      PlaybackLoading(
        :final reciterName,
        :final surahNumber,
        :final surahName,
      )
          when reciterName != null =>
        _Track(
          reciterName: reciterName,
          surahNumber: surahNumber,
          surahLabel: surahName.isEmpty
              ? loc.surahBadge(loc.number(surahNumber))
              : surahName,
          position: Duration.zero,
          duration: Duration.zero,
          playing: true,
        ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return BlocBuilder<PlaybackCubit, PlaybackState>(
      buildWhen: (previous, current) => playerSheetShouldRebuild(
        previous,
        current,
        dragging: _dragging != null,
      ),
      builder: (context, state) {
        final track = _trackOf(context, state);
        if (track == null) {
          // The track ended (or was stopped) while the sheet was open: close
          // it instead of leaving an empty sheet behind.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).maybePop();
          });
          return const SizedBox.shrink();
        }
        final maxMs = track.duration.inMilliseconds.toDouble();
        final cubit = context.read<PlaybackCubit>();
        final controls = switch (state) {
          PlaybackPlaying(
            :final speed,
            :final repeatMode,
            :final sleepTimer,
          ) =>
            (speed: speed, repeatMode: repeatMode, sleepTimer: sleepTimer),
          PlaybackPaused(
            :final speed,
            :final repeatMode,
            :final sleepTimer,
          ) =>
            (speed: speed, repeatMode: repeatMode, sleepTimer: sleepTimer),
          _ => (
              speed: 1.0,
              repeatMode: PlaybackRepeatMode.off,
              sleepTimer: null,
            ),
        };
        final value = (_dragging ?? track.position.inMilliseconds.toDouble())
            .clamp(0.0, maxMs > 0 ? maxMs : 0.0);
        return SingleChildScrollView(
          child: Padding(
            // `useSafeArea: true` only protects the top/sides of a modal sheet;
            // the bottom keeps the system inset so the transport row never sits
            // in the gesture/navigation strip on an edge-to-edge build.
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.lg + appBottomInset(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.reciterName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.surahLabel,
                  style: AppTheme.mutedAt(colors, 13),
                ),
                const SizedBox(height: AppSpacing.md),
                Slider(
                  value: value,
                  max: maxMs > 0 ? maxMs : 1,
                  label: _clock(Duration(milliseconds: value.round())),
                  onChanged: maxMs > 0
                      ? (next) => setState(() => _dragging = next)
                      : null,
                  onChangeEnd: maxMs > 0
                      ? (next) {
                          context
                              .read<PlaybackCubit>()
                              .seek(Duration(milliseconds: next.round()));
                          setState(() => _dragging = null);
                        }
                      : null,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _clock(Duration(milliseconds: value.round())),
                        style: AppTheme.mutedAt(colors, 12),
                      ),
                      Text(
                        _clock(track.duration),
                        style: AppTheme.mutedAt(colors, 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _OptionsRow(
                  loc: loc,
                  cubit: cubit,
                  speed: controls.speed,
                  repeatMode: controls.repeatMode,
                  sleepTimer: controls.sleepTimer,
                  onSleepPressed: () =>
                      _showSleepMenu(context, cubit, controls.sleepTimer),
                ),
                const SizedBox(height: AppSpacing.sm),
                _TransportRow(loc: loc, cubit: cubit, track: track),
              ],
            ),
          ),
        );
      },
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(width: AppSpacing.sm),
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
          onPressed: track.surahNumber > 1 ? cubit.previousSurah : null,
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
          onPressed: track.surahNumber > 0 && track.surahNumber < kSurahCount
              ? cubit.nextSurah
              : null,
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
