import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/insets.dart';
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
        // No track known yet (idle) — the mini player shows nothing.
        PlaybackLoading(:final reciterName, :final surahNumber) =>
          reciterName == null
              ? const SizedBox.shrink()
              : _PlaybackStrip(
                  reciterName: reciterName,
                  surahNumber: surahNumber,
                  busy: true,
                  playing: false,
                ),
        PlaybackFailed(:final kind) => _FailedStrip(kind: kind),
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
    // Scaffold strips the bottom padding from its bottomSheet slot, so the
    // inset is read from the frame view and applied inside the Material —
    // the strip keeps painting behind the system bar.
    return Material(
      color: colors.surface,
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs + appBottomInset(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TrackInfo(
                reciterName: reciterName,
                surahNumber: surahNumber,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _PlayToggle(busy: busy, playing: playing),
            IconButton(
              tooltip: loc.stopTooltip,
              icon: const Icon(Icons.stop),
              onPressed: () => context.read<PlaybackCubit>().stopAndReset(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({required this.reciterName, required this.surahNumber});

  final String reciterName;
  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.nowPlaying(reciterName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          loc.surahBadge(surahNumber.toArabicIndic),
          style: AppTheme.mutedFootnote(context),
        ),
        const _ProgressRow(),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackCubit, PlaybackState>(
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
          _ => (position: Duration.zero, duration: Duration.zero),
        };
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : null;
        return LinearProgressIndicator(value: progress, minHeight: 3);
      },
    );
  }
}

class _PlayToggle extends StatelessWidget {
  const _PlayToggle({required this.busy, required this.playing});

  final bool busy;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (busy) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: playing ? loc.pauseTooltip : loc.playTooltip,
      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
      onPressed: () => context.read<PlaybackCubit>().toggle(),
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
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: EdgeInsets.only(bottom: appBottomInset(context)),
        child: ErrorStrip(
          message,
          dismissTooltip: loc.stopTooltip,
          onDismiss: () => context.read<PlaybackCubit>().stopAndReset(),
        ),
      ),
    );
  }
}
