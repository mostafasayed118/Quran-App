import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import 'playback_cubit.dart';
import 'playback_state.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackCubit, PlaybackState>(
      builder: (context, state) => switch (state) {
        PlaybackInitial() => const SizedBox.shrink(),
        PlaybackFailed(:final kind) => _FailedStrip(kind: kind),
        PlaybackLoading(:final reciterName, :final surahNumber) =>
          _PlaybackStrip(
            reciterName: reciterName,
            surahNumber: surahNumber,
            position: null,
            duration: null,
            busy: true,
            playing: false,
          ),
        PlaybackPlaying(
          :final reciterName,
          :final surahNumber,
          :final position,
          :final duration,
        ) =>
          _PlaybackStrip(
            reciterName: reciterName,
            surahNumber: surahNumber,
            position: position,
            duration: duration,
            busy: false,
            playing: true,
          ),
        PlaybackPaused(
          :final reciterName,
          :final surahNumber,
          :final position,
          :final duration,
        ) =>
          _PlaybackStrip(
            reciterName: reciterName,
            surahNumber: surahNumber,
            position: position,
            duration: duration,
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
    required this.position,
    required this.duration,
    required this.busy,
    required this.playing,
  });

  final String reciterName;
  final int surahNumber;
  final Duration? position;
  final Duration? duration;
  final bool busy;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final dur = duration ?? Duration.zero;
    final pos = position ?? Duration.zero;
    final progress =
        dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : null;
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
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    LinearProgressIndicator(value: progress, minHeight: 3),
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
                icon: const Icon(Icons.close),
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
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  kind == PlaybackFailureKind.network
                      ? loc.playbackFailed
                      : loc.noReciters,
                  style: TextStyle(
                    color: colors.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: loc.stopTooltip,
              icon: const Icon(Icons.close),
              onPressed: () => context.read<PlaybackCubit>().stopAndReset(),
            ),
          ],
        ),
      ),
    );
  }
}
