import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/error_strip.dart';
import '../../../../l10n/app_localizations.dart';
import 'playback_cubit.dart';
import 'playback_state.dart';

/// Rebuild gate for the mini-player shell. Position ticks arrive ~5 Hz and
/// only feed the progress row, which owns its own [BlocBuilder]; every other
/// field change (track, status, duration, failure kind) rebuilds the shell.
bool miniPlayerShellShouldRebuild(
  PlaybackState previous,
  PlaybackState current,
) {
  if (previous.runtimeType != current.runtimeType) return true;
  return switch ((previous, current)) {
    (final PlaybackPlaying a, final PlaybackPlaying b) =>
      a.reciterName != b.reciterName ||
          a.surahNumber != b.surahNumber ||
          a.duration != b.duration,
    (final PlaybackPaused a, final PlaybackPaused b) =>
      a.reciterName != b.reciterName ||
          a.surahNumber != b.surahNumber ||
          a.duration != b.duration,
    _ => previous != current,
  };
}

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackCubit, PlaybackState>(
      buildWhen: miniPlayerShellShouldRebuild,
      builder: (context, state) => switch (state) {
        PlaybackInitial() => const SizedBox.shrink(),
        PlaybackFailed(:final kind) => _FailedStrip(kind: kind),
        PlaybackLoading(:final reciterName, :final surahNumber) =>
          _PlaybackStrip(
            reciterName: reciterName,
            surahNumber: surahNumber,
            busy: true,
            playing: false,
          ),
        PlaybackPlaying(:final reciterName, :final surahNumber) =>
          _PlaybackStrip(
            reciterName: reciterName,
            surahNumber: surahNumber,
            busy: false,
            playing: true,
          ),
        PlaybackPaused(:final reciterName, :final surahNumber) =>
          _PlaybackStrip(
            reciterName: reciterName,
            surahNumber: surahNumber,
            busy: false,
            playing: false,
          ),
      },
    );
  }
}

class _PlaybackStrip extends StatelessWidget {
  const _PlaybackStrip({
    required this.reciterName,
    required this.surahNumber,
    required this.busy,
    required this.playing,
  });

  final String reciterName;
  final int surahNumber;
  final bool busy;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.nowPlaying(reciterName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      loc.surahBadge(surahNumber.toArabicIndic),
                      style: AppTheme.mutedFootnote(context),
                    ),
                    BlocBuilder<PlaybackCubit, PlaybackState>(
                      builder: (context, state) {
                        final (:position, :duration) = switch (state) {
                          PlaybackPlaying(
                            :final position,
                            :final duration,
                          ) =>
                            (position: position, duration: duration),
                          PlaybackPaused(
                            :final position,
                            :final duration,
                          ) =>
                            (position: position, duration: duration),
                          _ => (
                              position: Duration.zero,
                              duration: Duration.zero,
                            ),
                        };
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : null;
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (busy)
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: playing ? loc.pauseTooltip : loc.playTooltip,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: () => context.read<PlaybackCubit>().toggle(),
                ),
              IconButton(
                tooltip: loc.stopTooltip,
                icon: const Icon(Icons.stop),
                onPressed: () => context.read<PlaybackCubit>().stopAndReset(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailedStrip extends StatelessWidget {
  const _FailedStrip({required this.kind});

  final PlaybackFailureKind kind;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final message = switch (kind) {
      PlaybackFailureKind.network => loc.playbackFailed,
      PlaybackFailureKind.backgroundUnavailable => loc.playbackBackgroundFailed,
      PlaybackFailureKind.noReciters => loc.playbackNoReciters,
    };
    return ErrorStrip(
      message,
      dismissTooltip: loc.stopTooltip,
      onDismiss: () => context.read<PlaybackCubit>().stopAndReset(),
    );
  }
}
