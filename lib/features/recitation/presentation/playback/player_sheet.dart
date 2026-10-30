import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import 'playback_cubit.dart';
import 'playback_state.dart';

/// Tracks a seek position while the thumb is held, otherwise mirrors the
/// stream.
class _Track {
  const _Track({
    required this.reciterName,
    required this.surahLabel,
    required this.position,
    required this.duration,
    required this.playing,
  });

  final String reciterName;
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
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
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
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds'.toArabicIndicDigits;
    }
    return '${d.inMinutes}:$seconds'.toArabicIndicDigits;
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
          surahLabel: surahName.isEmpty
              ? loc.surahBadge(surahNumber.toArabicIndic)
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
          surahLabel: surahName.isEmpty
              ? loc.surahBadge(surahNumber.toArabicIndic)
              : surahName,
          position: position,
          duration: duration,
          playing: false,
        ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return BlocBuilder<PlaybackCubit, PlaybackState>(
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
        final value = (_dragging ?? track.position.inMilliseconds.toDouble())
            .clamp(0.0, maxMs > 0 ? maxMs : 0.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    iconSize: 34,
                    tooltip: track.playing ? loc.pauseTooltip : loc.playTooltip,
                    icon: Icon(
                      track.playing ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () => context.read<PlaybackCubit>().toggle(),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  IconButton(
                    tooltip: loc.stopTooltip,
                    icon: const Icon(Icons.stop),
                    // The state-driven branch above closes the sheet once the
                    // cubit reaches its initial state; popping here as well
                    // could close the underlying route on a double pop.
                    onPressed: () =>
                        context.read<PlaybackCubit>().stopAndReset(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
